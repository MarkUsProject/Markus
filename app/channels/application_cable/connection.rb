module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      if request.session[:auth_type] == 'remote'
        self.current_user = User.find_by user_name: request.env['HTTP_X_FORWARDED_USER']
      end
      unless request.session[:user_name].nil?
        self.current_user = User.find_by user_name: request.session[:user_name]
      end
      self.current_user ||= User.find_by user_name: request.session[:real_user_name]
      if self.current_user.nil?
        reject_unauthorized_connection
      end
    end
  end
end
