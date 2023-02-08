namespace :markus do
  desc 'Rotate LTI private key'
  task lti_key: :environment do
    print('Creating new private key')
    key = OpenSSL::PKey::RSA.new(2048)
    FileUtils.mkdir_p(File.join(Settings.file_storage.lti ||
                                  File.join(Settings.file_storage.default_root_path), 'lti'))
    f = File.new(LtiClient::KEY_PATH, 'w')
    f.write(key.to_s)
    f.close
  end
end
