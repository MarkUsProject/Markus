# updates repo permissions file by rewriting the entire file
# according to the current state of the database
class UpdateRepoPermissionsJob < ApplicationJob
  def self.show_status(_status); end

  # If another job that will update the repo permissions file is alread enqueued, then
  # do not enqueue this one.
  around_enqueue do |job, block|
    block.call if Redis::Namespace.new(Rails.root.to_s).setnx('repo_permissions', job.id)
  end

  # In case an error occurs during execution, ensure that the repo_permissions redis key
  # gets cleaned up.
  after_perform do |job|
    redis = Redis::Namespace.new(Rails.root.to_s)
    if redis.get('repo_permissions') == job.id.to_s
      redis.del('repo_permissions')
    end
  end

  # Update repo permissions file. After getting the permissions from the database,
  # delete the key in redis so that any future job will run (with updated info)
  def perform(repo_class)
    redis = Redis::Namespace.new(Rails.root.to_s)
    redis.del('repo_permissions')
    permissions = repo_class.get_all_permissions
    full_access_users = repo_class.get_full_access_users
    repo_class.update_permissions_file(permissions, full_access_users)
  end
end
