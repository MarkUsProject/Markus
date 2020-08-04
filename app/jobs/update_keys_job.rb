# updates authorized_key file by rewriting the entire file
# according to the current state of the database
class UpdateKeysJob < ApplicationJob
  queue_as Rails.configuration.x.queues.update_keys

  def self.show_status(_status); end

  def perform
    FileUtils.mkdir_p(Rails.configuration.key_storage)
    auth_keys_file = File.join(Rails.configuration.key_storage, KeyPair::AUTHORIZED_KEYS_FILE)
    FileUtils.touch(auth_keys_file) unless File.exist? auth_keys_file
    File.open(auth_keys_file, 'r+') do |f|
      f.flock(File::LOCK_EX)
      begin
        f.truncate(0)
        KeyPair.joins(:user).pluck('users.user_name', :public_key).each do |name, key|
          f.write(KeyPair.full_key_string(name, key) + "\n")
        end
      ensure
        f.flock(File::LOCK_UN)
      end
    end
  end
end
