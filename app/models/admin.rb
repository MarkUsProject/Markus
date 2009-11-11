# we need repository permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')
class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT
  
  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  
  # Convenience method which returns a configuration Hash for the
  # repository lib
  def self.repo_config
    # create config
    conf = Hash.new
    conf["IS_REPOSITORY_ADMIN"] = markus_config_repository_admin?
    conf["REPOSITORY_PERMISSION_FILE"] = markus_config_repository_permission_file
    return conf
  end
  
  private
  
  # Adds read and write permissions for each newly created admin user
  def grant_repository_permissions
    # If we're not the repository admin, bail out
    return if !markus_config_repository_admin?
    
    conf = Admin.repo_config
    repo = Repository.get_class(markus_config_repository_type, conf)
    repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
    repo.set_bulk_permissions(repo_names, {self.user_name => Repository::Permission::READ_WRITE})
  end
  
  # Revokes read and write permissions for a deleted admin user
  def revoke_repository_permissions
    return if !markus_config_repository_admin?
    
    conf = Admin.repo_config
    repo = Repository.get_class(markus_config_repository_type, conf)
    repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
    repo.delete_bulk_permissions(repo_names, [self.user_name])
  end
 
end
