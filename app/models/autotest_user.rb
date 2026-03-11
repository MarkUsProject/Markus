# Model for Autotest user
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
class AutotestUser < User
  include AutomatedTestsHelper::AutotestApi

  USERNAME = '.autotestuser'.freeze

  def self.find_or_create
    server_user = AutotestUser.find_or_create_by(user_name: AutotestUser::USERNAME) do |user|
      user.first_name = 'Autotest'
      user.last_name = 'User'
    end
    server_user.reset_api_key if server_user.api_key.nil?
    server_user
  end

  def reset_api_key
    super
    AutotestSetting.find_each do |setting|
      update_credentials(setting)
    end
  end
end
