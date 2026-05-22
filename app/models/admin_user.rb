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
class AdminUser < User
  ADMIN_USERNAME = '.admin'.freeze

  def self.find_or_create
    user = AdminUser.find_or_create_by!(user_name: ADMIN_USERNAME) do |admin|
      admin.first_name = 'admin'
      admin.last_name = 'user'
    end
    user.reset_api_key
    user
  end
end
