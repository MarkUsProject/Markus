namespace :markus do
  desc 'Rotate LTI private key'
  task lti_key: :environment do
    print('Creating new private key')
    key = OpenSSL::PKey::RSA.new(2048)
    FileUtils.mkdir_p(File.dirname(LtiClient::KEY_PATH))
    f = File.new(LtiClient::KEY_PATH, 'w')
    f.write(key.to_s)
    f.close
  end
end
