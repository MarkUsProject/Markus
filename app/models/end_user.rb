# Subclass of User that can be associated with Roles
class EndUser < User
  has_many :roles, foreign_key: :user_id, inverse_of: :end_user
  validates_presence_of :roles, unless: -> { self.new_record? }
  has_many :courses, through: :roles

  def visible_courses
    self.courses.where.not('roles.type': 'Student')
        .or(self.courses.where('courses.is_hidden': false, 'roles.hidden': false))
  end
end
