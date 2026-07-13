describe LtiKeyStore do
  # Real PEMs in a real temp dir: exercises the actual glob/sort/read logic
  # rather than a mock of it.
  let(:tmp_dir) { Dir.mktmpdir }

  # Writes a key whose filename encodes +created+, so `created_at` (and
  # therefore all the age math) treats it as having been created then.
  def write_key(created, key: OpenSSL::PKey::RSA.new(2048))
    path = File.join(tmp_dir, "lti_key_#{created.utc.strftime('%Y%m%dT%H%M%SZ')}.pem")
    File.write(path, key.to_pem)
    path
  end

  before do
    allow(Settings.lti.rotation).to receive_messages(key_dir: tmp_dir, max_age_days: 90, overlap_days: 7)
    allow(Settings.lti.rotation).to receive(:current_key).and_return(nil)
    # File.exist? is called by unrelated machinery (autoloading, etc.), so a
    # default call-through is required before stubbing it for a specific path.
    allow(File).to receive(:exist?).and_call_original
  end

  after { FileUtils.remove_entry(tmp_dir) }

  describe '.key_paths' do
    it 'returns an empty array when no keys exist anywhere' do
      allow(File).to receive(:exist?).with(LtiClient::KEY_PATH).and_return(false)
      expect(LtiKeyStore.key_paths).to be_empty
    end

    it 'orders keys newest first' do
      old = write_key(30.days.ago)
      new = write_key(1.day.ago)
      expect(LtiKeyStore.key_paths).to eq([new, old])
    end

    # Existing deployments upgrade with a key.pem and no keys/ directory; this
    # fallback is what lets them keep signing until their first rotation.
    # Remove only when the legacy path is formally deprecated.
    context 'when the rotation directory is empty' do
      it 'falls back to the legacy key.pem' do
        allow(File).to receive(:exist?).with(LtiClient::KEY_PATH).and_return(true)
        expect(LtiKeyStore.key_paths).to eq([LtiClient::KEY_PATH])
      end
    end

    context 'when the rotation directory has keys' do
      it 'ignores the legacy key.pem' do
        allow(File).to receive(:exist?).with(LtiClient::KEY_PATH).and_return(true)
        path = write_key(1.day.ago)
        expect(LtiKeyStore.key_paths).to eq([path])
      end
    end
  end

  describe '.current_key' do
    it 'raises when no key is available' do
      allow(File).to receive(:exist?).with(LtiClient::KEY_PATH).and_return(false)
      expect { LtiKeyStore.current_key }.to raise_error(/No LTI signing key/)
    end

    it 'signs with the newest key' do
      write_key(30.days.ago)
      newest = OpenSSL::PKey::RSA.new(2048)
      write_key(1.day.ago, key: newest)
      expect(LtiKeyStore.current_key.to_pem).to eq(newest.to_pem)
    end

    context 'when Settings.lti.rotation.current_key is set' do
      it 'signs with the pinned key rather than the newest' do
        pinned = OpenSSL::PKey::RSA.new(2048)
        pinned_path = write_key(30.days.ago, key: pinned)
        write_key(1.day.ago) # newer, but should be ignored
        allow(Settings.lti.rotation).to receive(:current_key).and_return(File.basename(pinned_path))

        expect(LtiKeyStore.current_key.to_pem).to eq(pinned.to_pem)
      end
    end
  end

  describe '.public_jwks' do
    it 'publishes every key in the set' do
      write_key(30.days.ago)
      write_key(1.day.ago)

      kids = LtiKeyStore.public_jwks[:keys].pluck(:kid)
      expect(kids.length).to eq(2)
    end

    it 'publishes the current signer' do
      write_key(1.day.ago)
      kids = LtiKeyStore.public_jwks[:keys].pluck(:kid)
      expect(kids).to include(LtiKeyStore.current_jwk.kid)
    end

    it 'exports public members only' do
      write_key(1.day.ago)
      jwk = LtiKeyStore.public_jwks[:keys].first
      # 'd' is the RSA private exponent; it must never be published.
      expect(jwk.keys.map(&:to_s)).not_to include('d')
    end

    it 'produces a key set that verifies a token signed by the current key' do
      write_key(1.day.ago)
      jwk = LtiKeyStore.current_jwk
      token = JWT.encode({ test: 'payload' }, jwk.keypair, 'RS256', { kid: jwk.kid })
      jwks = JSON.parse(LtiKeyStore.public_jwks.to_json) # as Canvas receives it

      expect { JWT.decode(token, nil, true, algorithms: ['RS256'], jwks: jwks) }.not_to raise_error
    end

    it 'still verifies a token signed by a retired key during the overlap' do
      retired = OpenSSL::PKey::RSA.new(2048)
      write_key(30.days.ago, key: retired)
      write_key(1.day.ago) # newer key takes over as signer

      retired_jwk = JWT::JWK.new(retired)
      token = JWT.encode({ test: 'payload' }, retired_jwk.keypair, 'RS256', { kid: retired_jwk.kid })
      jwks = JSON.parse(LtiKeyStore.public_jwks.to_json)

      expect { JWT.decode(token, nil, true, algorithms: ['RS256'], jwks: jwks) }.not_to raise_error
    end
  end

  describe '.rotate!' do
    it 'creates a new key' do
      expect { LtiKeyStore.rotate! }.to change { LtiKeyStore.key_paths.length }.by(1)
    end

    it 'makes the new key the current signer' do
      write_key(1.day.ago)
      path = LtiKeyStore.rotate!
      expect(LtiKeyStore.key_paths.first).to eq(path)
    end

    it 'writes the key with owner-only permissions' do
      path = LtiKeyStore.rotate!
      expect(File.stat(path).mode & 0o777).to eq(0o600)
    end

    it 'creates the key directory if it does not exist' do
      nested = File.join(tmp_dir, 'nested')
      allow(Settings.lti.rotation).to receive(:key_dir).and_return(nested)
      LtiKeyStore.rotate!
      expect(Dir.exist?(nested)).to be true
    end
  end

  describe '.rotate_if_due!' do
    it 'rotates when no key exists' do
      allow(File).to receive(:exist?).with(LtiClient::KEY_PATH).and_return(false)
      expect { LtiKeyStore.rotate_if_due! }.to change { LtiKeyStore.key_paths.length }.by(1)
    end

    it 'rotates when the current key is past its max age' do
      write_key(91.days.ago)
      expect { LtiKeyStore.rotate_if_due! }.to change { LtiKeyStore.key_paths.length }.by(1)
    end

    it 'does not rotate when the current key is within its max age' do
      write_key(89.days.ago)
      expect { LtiKeyStore.rotate_if_due! }.not_to(change { LtiKeyStore.key_paths.length })
    end

    it 'returns nil when no rotation occurs' do
      write_key(1.day.ago)
      expect(LtiKeyStore.rotate_if_due!).to be_nil
    end
  end

  describe '.prune!' do
    it 'never prunes the current signer, however old it is' do
      write_key(500.days.ago)
      expect { LtiKeyStore.prune! }.not_to(change { LtiKeyStore.key_paths.length })
    end

    it 'keeps a key retired less recently than the overlap window' do
      # Retired 1 day ago (when its successor was created) -- inside the 7d window.
      old = write_key(100.days.ago)
      write_key(1.day.ago)

      LtiKeyStore.prune!
      expect(LtiKeyStore.key_paths).to include(old)
    end

    it 'prunes a key retired longer ago than the overlap window' do
      # Retired 30 days ago (when its successor was created) -- past the 7d window.
      stale = write_key(60.days.ago)
      write_key(30.days.ago)
      write_key(1.day.ago)

      LtiKeyStore.prune!
      expect(LtiKeyStore.key_paths).not_to include(stale)
    end

    it 'retains the most recently retired key while pruning older ones' do
      stale = write_key(60.days.ago)
      recently_retired = write_key(30.days.ago)
      current = write_key(1.day.ago)

      LtiKeyStore.prune!
      expect(LtiKeyStore.key_paths).to contain_exactly(current, recently_retired)
      expect(LtiKeyStore.key_paths).not_to include(stale)
    end

    it 'returns the paths it pruned' do
      stale = write_key(60.days.ago)
      write_key(30.days.ago)
      write_key(1.day.ago)

      expect(LtiKeyStore.prune!).to eq([stale])
    end

    it 'is idempotent' do
      write_key(60.days.ago)
      write_key(30.days.ago)
      write_key(1.day.ago)

      LtiKeyStore.prune!
      expect { LtiKeyStore.prune! }.not_to(change { LtiKeyStore.key_paths.length })
    end
  end

  describe '.created_at' do
    it 'parses the UTC timestamp from the filename' do
      created = 5.days.ago
      path = write_key(created)
      expect(LtiKeyStore.created_at(path)).to be_within(1.second).of(created)
    end

    it 'falls back to mtime for a file without a timestamp in its name' do
      path = File.join(tmp_dir, 'key.pem')
      File.write(path, OpenSSL::PKey::RSA.new(2048).to_pem)
      expect(LtiKeyStore.created_at(path)).to be_within(1.minute).of(Time.now.utc)
    end
  end
end
