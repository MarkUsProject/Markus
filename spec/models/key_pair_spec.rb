describe KeyPair do
  context 'validations' do
    it { is_expected.to belong_to :user }
    it { is_expected.to validate_presence_of :public_key }
    it { is_expected.to validate_presence_of :user }
    it 'should not validate a multiline key' do
      expect(build(:key_pair, public_key: "ssh-rsa\nabcd").validate).to be false
    end
    it 'should not validate an invalid key type' do
      expect(build(:key_pair, public_key: 'aaaaaa abcd').validate).to be false
    end
    it 'should not validate an empty key' do
      expect(build(:key_pair, public_key: 'ssh-rsa').validate).to be false
    end
    it 'should validate a valid key' do
      expect(build(:key_pair).validate).to be true
    end
  end
  context 'callbacks' do
    it 'should call UpdateKeysJob.perform_later on creation' do
      expect(UpdateKeysJob).to receive(:perform_later)
      create :key_pair
    end
    it 'should call UpdateKeysJob.perform_later on destruction' do
      key_pair = create :key_pair
      expect(UpdateKeysJob).to receive(:perform_later)
      key_pair.destroy
    end
    it 'should strip the public_key before validation' do
      key = '    ssh-rsa something   '
      key_pair = build :key_pair, public_key: key
      expect(key_pair.public_key).to eq key
      key_pair.validate
      expect(key_pair.public_key).to eq key.strip
    end
  end

  context 'self.full_key_string' do
    it 'should be formatted properly' do
      allow(Rails.configuration.x.repository).to receive(:git_shell).and_return('shell')
      allow(Rails.configuration.action_controller).to receive(:relative_url_root).and_return('/test')
      expected = "command=\"LOGIN_USER=a RELATIVE_URL_ROOT=/test shell\",#{KeyPair::AUTHORIZED_KEY_ARGS} b"
      expect(KeyPair.full_key_string('a', 'b')).to eq expected
    end
  end
end
