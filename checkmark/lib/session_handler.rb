

# Responsible for maintaining sessions and querying session status
# All controllers are expected to extend this module (already by default)
module SessionHandler
  
  # TODO implement session timeout limit on a per-role basis,
  # e.g. faculty has more timeout limit than students
  MAX_SESSION_PERIOD = 3600  # session timeout in seconds
  
  # Note: setter method for current_user is defined in login controller 
  # since other controllers do not need ability to set this

  # Retrieve current user for this session.
  # Call only when necessary and use local variables 
  # since user is fetched from DB on every call to this method
  def current_user
    # retrieve from database on every request instead of 
    # storing it as global variable when current_user= 
    # is called to prevent user information becoming stale.
    (session[:uid] && User.find_by_id(session[:uid])) || nil
  end
  
  # Check if there's any user associated with this session
  def logged_in?
    session[:uid] != nil
  end
  
  # Check if current user matches given role.
  # Does not check if user is logged in
  def authorized?(role='student')
    user = current_user
    user ? user.role.casecmp(role) : false
  end
  
  # Checks user satsifies the following conditions:
  # => User has an active session and is not expired
  # => User has privilege to view the page/perform action
  # If not, then user is redirected to login page for authentication.
  def authenticate
    if !session_expired? && logged_in?
      refresh_timeout
    else
      clear_session
      session[:redirect_uri] = request.request_uri  # save current uri
      flash[:login_notice] = "Please log in"
      redirect_to :controller => 'checkmark', :action => 'login'
    end
  end
  
  # Refreshes the timeout for this session to be 
  # MAX_SESSION_PERIOD seconds from now
  def refresh_timeout
    session[:timeout] = MAX_SESSION_PERIOD.seconds.from_now
  end
    
  def session_expired?
    session[:timeout] == nil || session[:timeout] < Time.now
  end
  
  # Clear this current user's session set by this app
  def clear_session
    session[:timeout] = nil
    session[:uid] = nil
  end
  
  
  
  # TODO I got the following snippet from Acts_as_authenticated
  # authorization module. It looks interesting but I don't know what the 
  # hell it's doing.  Can we use this?
  # 
  #private
  #@@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
  # gets BASIC auth info
  #def get_auth_data
  #  auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
  #  auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
  #  return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
  #end
  
end
