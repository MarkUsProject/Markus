# frozen_string_literal: true

require 'time'

# Manages the RSA key material MarkUs uses to sign LTI 1.3 client_credentials
# assertions to Canvas, and to publish its public JWKS.
#
# Rotation model (zero-downtime):
#   * Keys live as PEM files in key_dir, named lti_key_<UTC-timestamp>.pem.
#   * The "current" signer is the newest file (paths sorted lexicographically,
#     which matches chronological order given the zero-padded UTC timestamp),
#     overridable via Settings.lti.rotation.current_key.
#   * public_jwks publishes ALL keys present, so Canvas can still verify
#     assertions signed by an outgoing key until they expire and its JWKS
#     cache refreshes.
#   * rake markus:rotate_if_due adds a new key when the current one is past
#     its max age; rake markus:prune_keys removes keys past the overlap window.
module LtiKeyStore
  module_function

  KEY_GLOB = 'lti_key_*.pem'

  def key_dir
    Settings.lti&.rotation&.key_dir ||
      File.join(Settings.file_storage.default_root_path, 'lti', 'keys')
  end

  # All private-key PEM paths, newest first. If the rotation dir is empty,
  # fall back to the legacy single key.pem (LtiClient::KEY_PATH).
  def key_paths
    paths = Dir.glob(File.join(key_dir, KEY_GLOB)).sort.reverse
    return paths if paths.any?

    File.exist?(LtiClient::KEY_PATH) ? [LtiClient::KEY_PATH] : []
  end

  # The RSA key MarkUs signs NEW assertions with.
  def current_key
    path = explicit_current || key_paths.first
    raise 'No LTI signing key found' if path.nil?

    OpenSSL::PKey::RSA.new(File.read(path))
  end

  # JWK wrapper for the current signer (used to set the `kid` header).
  def current_jwk
    JWT::JWK.new(current_key)
  end

  # Public JWKS: every published key, exported public-only.
  # NB: JWT::JWK#export returns public members only unless include_private: true.
  def public_jwks
    { keys: key_paths.map { |p| JWT::JWK.new(OpenSSL::PKey::RSA.new(File.read(p))).export } }
  end

  # Optional explicit override, e.g. Settings.lti.rotation.current_key = 'lti_key_20260101T000000Z.pem'
  # Raises rather than silently falling back to the newest key: pinning is a
  # deliberate operator action (typically compromise response), so quietly
  # signing with a different key would defeat the point and hide the mistake.
  def explicit_current
    name = Settings.lti&.rotation&.current_key
    return if name.nil?

    path = File.join(key_dir, name)
    raise "Pinned LTI signing key not found: #{path} (check Settings.lti.rotation.current_key)" unless File.exist?(path)

    path
  end

  # Creation time encoded in the filename (UTC); falls back to mtime.
  def created_at(path)
    ts = File.basename(path)[/\d{8}T\d{6}Z/]
    ts ? Time.parse(ts).utc : File.mtime(path).utc
  end

  # Mint a new key; it becomes the current signer. Returns its path.
  def rotate!
    FileUtils.mkdir_p(key_dir)
    key = OpenSSL::PKey::RSA.new(2048)
    path = File.join(key_dir, "lti_key_#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}.pem")
    File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) { |f| f.write(key.to_pem) }
    Rails.logger.info("LTI key rotated: #{File.basename(path)} (kid=#{JWT::JWK.new(key).kid})")
    path
  end

  # Rotate only if the current signer is past its max age (or there is none).
  def rotate_if_due!
    max_age = Settings.lti.rotation.max_age_days.days
    current = key_paths.first
    age = current && (Time.now.utc - created_at(current))
    return rotate! if age.nil? || age > max_age

    Rails.logger.info("LTI key #{(age / 1.day).round(1)}d old; no rotation (threshold #{max_age / 1.day}d)")
    nil
  end

  # Delete retired keys past the overlap window. A key is retired when its
  # successor was created. Neither the newest key nor a key pinned via
  # Settings.lti.rotation.current_key is ever pruned -- deleting the current
  # signer would leave MarkUs unable to sign.
  def prune!
    overlap = Settings.lti.rotation.overlap_days.days
    paths = key_paths
    pinned = explicit_current
    now = Time.now.utc

    paths.each_with_index.filter_map do |path, i|
      next if i.zero?
      next if pinned && path == pinned

      age = now - created_at(paths[i - 1])
      next unless age > overlap

      File.delete(path)
      Rails.logger.info("Pruned LTI key #{File.basename(path)} (retired #{(age / 1.day).round(1)}d ago)")
      path
    end
  end
end
