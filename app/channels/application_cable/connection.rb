module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      if request.session[:real_user_name].nil?
        reject_unauthorized_connection
      else
        self.current_user = User.find_by user_name: request.session[:real_user_name]
      end
    end
  end
end
