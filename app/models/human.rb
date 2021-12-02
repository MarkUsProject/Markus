# Subclass of User for "Human" users (Admin, Student, TA)
class Human < User
  has_many :roles, foreign_key: :user_id, inverse_of: :human
  validates_presence_of :roles, unless: -> { self.new_record? }
  has_many :courses, through: :roles

  def visible_courses
    self.courses.where.not('roles.type': 'Student')
        .or(self.courses.where('courses.is_hidden': false, 'roles.hidden': false))
  end
end
