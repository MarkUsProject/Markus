# Subclass of User meant for regular users
class EndUser < User
  def visible_courses
    self.courses.where.not('roles.type': 'Student')
        .or(self.courses.where('courses.is_hidden': false, 'roles.hidden': false))
  end
end
