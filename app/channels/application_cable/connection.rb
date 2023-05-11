module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      self.current_user = User.find_by user_name: cookies.encrypted["_markus_session_csc108"]["real_user_name"]
    end
  end
end
