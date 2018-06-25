class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT

  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }

end
