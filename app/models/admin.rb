# we need repository permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')
class Admin < User
  
  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT
  
  private
  
  # Adds read and write permissions for each newly created admin user
  def grant_repository_permissions
    Group.all.each do |group|
      if group.repository_external_commits_only?
        group.repo.add_user(self.user_name, Repository::Permission::READ_WRITE)
      end
    end
  end
  
  # Revokes read and write permissions for a deleted admin user
  def revoke_repository_permissions
    Group.all.each do |group|
      if group.repository_external_commits_only?
        group.repo.remove_user(self.user_name)
      end
    end
  end
  
end
