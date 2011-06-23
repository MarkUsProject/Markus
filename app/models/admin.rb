# we need repository permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')
class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT

  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  after_update  :maintain_repository_permissions

end
