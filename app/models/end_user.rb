# Subclass of User meant for regular users
class EndUser < User
  CSV_ORDER = (
    Settings.end_user_csv_order || %w[user_name last_name first_name id_number email]
  ).map(&:to_sym).freeze

  def visible_courses
    self.courses.where('roles.hidden': false)
        .where.not('courses.is_hidden': true, 'roles.type': 'Student')
  end
end
