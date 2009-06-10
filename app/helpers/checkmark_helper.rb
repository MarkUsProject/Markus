module CheckmarkHelper
  
  protected
  
  # Sets current user for this session
  def current_user=(user)
    session[:uid] = (user.blank? || !user.kind_of?(User)) ? nil : user.id 
  end
  
  def get_blank_message(blank_login, blank_password)
    return "" unless blank_login || blank_password
    
    message = "Your "
    message += "CDF login " if blank_login
    message += "and " if blank_login && blank_password
    message += "password " if blank_password
    
    message + "must not be blank."
  end
  
end
