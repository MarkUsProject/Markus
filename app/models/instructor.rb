# Instructor user for a given course.
class Instructor < Role
  after_create { Repository.get_class.update_permissions }
  after_destroy { Repository.get_class.update_permissions }
  validate :associated_user_is_an_end_user, unless: -> { self.admin_role? }

  has_many :memberships, dependent: :delete_all, foreign_key: 'role_id', inverse_of: :role
end
