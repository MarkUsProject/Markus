# Model for Autotest user
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
