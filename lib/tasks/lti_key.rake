namespace :markus do
  desc 'Rotate LTI private key'
  task lti_key: :environment do
    print('Creating new private key')
    key = OpenSSL::PKey::RSA.new(2048)
    file_path = Settings.lti.key_path
    f = File.new("#{file_path}/key.pem", 'w')
    f.write(key.to_s)
    f.close
  end
end
