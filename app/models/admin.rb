# Admin user for a given course.
class Admin < Role
  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }

end
