class Admin < User
  SESSION_TIMEOUT = Settings.admin_session_timeout

  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }

end
