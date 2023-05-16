module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      self.current_user = User.find_by user_name: request.session[:real_user_name]
      if self.current_user.nil?
        reject_unauthorized_connection
      end
    end
  end
end
