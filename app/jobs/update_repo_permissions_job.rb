# updates repo permissions file by rewriting the entire file
# according to the current state of the database
class UpdateRepoPermissionsJob < ApplicationJob
  def self.show_status(_status); end

  # If another job that will update the repo permissions file is alread enqueued, then
  # do not enqueue this one
  around_enqueue do |job, block|
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    block.call if redis.setnx('repo_permissions', job.job_id)
    redis.expire('repo_permissions', 300) # expire the key just in case
  end

  # Update repo permissions file. After getting the permissions from the database,
  # delete the key in redis so that any future job will run (with updated info)
  def perform(repo_class_name)
    repo_class = repo_class_name.constantize
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    redis.del('repo_permissions')
    permissions = repo_class.get_all_permissions
    repo_class.update_permissions_file(permissions)
  ensure
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    if redis.get('repo_permissions') == self.job_id
      redis.del('repo_permissions')
    end
  end
end
