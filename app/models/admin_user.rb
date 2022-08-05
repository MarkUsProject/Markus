class AdminUser < User
  ADMIN_USERNAME = '.admin'.freeze

  def self.find_or_create
    user = AdminUser.find_or_create_by!(user_name: ADMIN_USERNAME) do |admin|
      admin.first_name = 'admin'
      admin.last_name = 'admin'
    end
    user.reset_api_key
    user
  end
end
