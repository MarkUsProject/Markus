# Subclass of User for "Human" users (Admin, Student, TA)
class Human < User
  has_many :roles, foreign_key: :user_id, inverse_of: :human
  validates_presence_of :roles, unless: -> { self.new_record? }

  def visible_courses
    courses = Course.joins(:roles).where('roles.id': self.roles)
    courses.where.not('roles.type': 'Student').or(courses.where('courses.is_hidden': false, 'roles.hidden': false))
  end
end
