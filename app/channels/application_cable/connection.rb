module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      unless request.session.nil?
        self.current_user = User.find_by user_name: request.session[:user_name]
      end
      self.current_user ||= User.find_by user_name: request.session[:real_user_name]
      if self.current_user.nil?
        reject_unauthorized_connection
      end
    end
  end
end
