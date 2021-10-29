class TestServer < User
  USERNAME = '.testserver'.freeze

  def self.find_or_create
    server_user = TestServer.find_or_create_by(user_name: TestServer::USERNAME) do |user|
      user.first_name = 'Autotest'
      user.last_name = 'Server'
    end
    server_user.reset_api_key if server_user.api_key.nil?
    server_user
  end
end
