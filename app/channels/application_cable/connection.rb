module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :real_user
    def connect
      if request.session[:auth_type] == 'remote' && Settings.remote_auth_login_url.present?
        self.real_user = User.find_by user_name: request.env['HTTP_X_FORWARDED_USER']
      else
        self.real_user = User.find_by(user_name: request.session[:real_user_name])
      end
      reject_unauthorized_connection if self.real_user.nil?
      unless request.session[:user_name].nil?
        self.current_user = User.find_by user_name: request.session[:user_name]
      end
      self.current_user ||= self.real_user
    end
  end
end
