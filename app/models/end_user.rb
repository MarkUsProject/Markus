# Subclass of User meant for regular users
class EndUser < User
  CSV_ORDER = (
    Settings.end_user_csv_order || %w[user_name last_name first_name id_number email]
  ).map(&:to_sym).freeze

  def visible_courses
    self.courses.where.not('roles.type': 'Student')
        .or(self.courses.where('courses.is_hidden': false, 'roles.hidden': false))
  end
end
