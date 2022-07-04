# updates authorized_key file by rewriting the entire file
# according to the current state of the database
class UpdateKeysJob < ApplicationJob
  def self.show_status(_status); end

  # If another job that will update the authorized_keys file is alread enqueued, then
  # do not enqueue this one.
  around_enqueue do |job, block|
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Redis.new(url: Settings.redis.url))
    block.call if redis.setnx('authorized_keys', job.job_id)
    redis.expire('authorized_keys', 300) # expire the key just in case
  end

  # Update authorized_keys file. After getting the key pair info from the database,
  # delete the key in redis so that any future job will run (with updated info).
  def perform
    FileUtils.mkdir_p(Settings.repository.storage)
    auth_keys_file = File.join(Settings.repository.storage, KeyPair::AUTHORIZED_KEYS_FILE)
    FileUtils.touch(auth_keys_file) unless File.exist? auth_keys_file
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Redis.new(url: Settings.redis.url))
    redis.del('authorized_keys')
    data = KeyPair.joins(:user).pluck('users.user_name', :public_key)
    File.open(auth_keys_file, 'r+') do |f|
      f.flock(File::LOCK_EX)
      begin
        f.truncate(0)
        data.each { |name, key| f.write(KeyPair.full_key_string(name, key) + "\n") }
      ensure
        f.flock(File::LOCK_UN)
      end
    end
  ensure
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Redis.new(url: Settings.redis.url))
    if redis.get('authorized_keys') == self.job_id
      redis.del('authorized_keys')
    end
  end
end
