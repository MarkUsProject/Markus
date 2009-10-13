# we need repository permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository_factory')
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')
class Admin < User
  
  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT
   
  private
  
  # Adds read and write permissions for each newly created admin user
  def grant_repository_permissions
    # If we're not the repository admin, bail out
    return if !IS_REPOSITORY_ADMIN
    repo = Repository.get_class(REPOSITORY_TYPE)
    repo_names = Group.all.collect do |group| group.repo_name end
    repo.set_bulk_permissions(repo_names, {self.user_name => Repository::Permission::READ_WRITE})
  end
  
  # Revokes read and write permissions for a deleted admin user
  def revoke_repository_permissions
    return if !IS_REPOSITORY_ADMIN
    repo = Repository.get_class(REPOSITORY_TYPE)
    repo_names = Group.all.collect do |group| group.repo_name end
    repo.delete_bulk_permissions(repo_names, [self.user_name])  
  end  
 
end
