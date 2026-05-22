# Subclass of User meant for regular users
# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: users
#
#  id           :integer          not null, primary key
#  api_key      :string
#  display_name :string           not null
#  email        :string
#  first_name   :string
#  id_number    :string
#  last_name    :string
#  locale       :string           default("en"), not null
#  theme        :integer          default("light"), not null
#  time_zone    :string           not null
#  type         :string
#  user_name    :string           not null
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_users_on_api_key    (api_key) UNIQUE
#  index_users_on_user_name  (user_name) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class EndUser < User
  CSV_ORDER = (
    Settings.end_user_csv_order || %w[user_name last_name first_name id_number email]
  ).map(&:to_sym).freeze

  def visible_courses
    active_courses = self.courses.where('roles.hidden': false)
    active_courses.where.not('roles.type': 'Student')
                  .or(active_courses.where('courses.is_hidden': false))
  end
end
