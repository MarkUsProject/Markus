# Instructor user for a given course.
class Instructor < Role
  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }

end
