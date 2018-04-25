# we need repository permission constants
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')
class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT

  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }
  after_update   { Repository.get_class.update_permissions }

end
