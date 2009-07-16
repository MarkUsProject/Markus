# Responsible for maintaining sessions and querying session status
# All controllers are expected to extend this module (already by default)
module SessionHandler
  
  protected
  
  
  # Note: setter method for current_user is defined in login controller 
  # since other controllers do not need ability to set this

  # Retrieve current user for this session, or nil if none exists
  def current_user
    # retrieve from database on every request instead of 
    # storing it as global variable when current_user= 
    # is called to prevent user information becoming stale.
    @current_user ||= (session[:uid] && User.find_by_id(session[:uid])) || nil
  end
  
  # Check if there's any user associated with this session
  def logged_in?
    session[:uid] != nil
  end
  
  # Check if current user matches given role.
  def authorized?(type=Admin)
    user = current_user
    if user.nil?
      return false
    end
    return user.is_a?(type)
  end
  
  # Checks user satsifies the following conditions:
  # => User has an active session and is not expired
  # => User has privilege to view the page/perform action
  # If not, then user is redirected to login page for authentication.
  def authenticate
    # Note: testing depends on the fact that 'authenticated' means having the 
    # session['uid'] and session['timeout'] set appropriately.  Make sure to 
    # change AuthenticatedControllerTest if this is changed.
    if !session_expired? && logged_in?
      refresh_timeout  # renew timeout for this session
      @current_user = current_user
    else
      # cleanup expired session stuff
      clear_session
      cookies.delete :auth_token
      reset_session
      
      session[:redirect_uri] = request.request_uri  # save current uri
      
      # figure out how we want to explain this to users
      if session_expired?
        flash[:login_notice] = "Your session has expired. Please log in"
      else
        flash[:login_notice] = "Please log in"
      end
      
      if request.xhr?
        session[:redirect_uri] = request.referer
        render :update do |page|
          page.redirect_to :controller => 'main', :action => 'login'
        end
      else
        redirect_to :controller => 'main', :action => 'login'
      end
    end
  end
  
  # Helper method to check if current user is authorized given a 
  # specific role. 
  def authorize_only_for_admin
    unless authorized?(Admin)
      render :file => "#{RAILS_ROOT}/public/404.html",  
        :status => 404
    end
  end

  def authorize_for_ta_and_admin
    unless authorized?(Admin) || authorized?(Ta)
      render :file => "#{RAILS_ROOT}/public/404.html",  
        :status => 404
    end
  end
  
  def authorize_for_student
    unless authorized?(Student)
      render :file => "#{RAILS_ROOT}/public/404.html",  
        :status => 404
    end
  end

  def authorize_for_student_and_ta
    unless authorized?(Ta) || authorized?(Student)
      render :file => "#{RAILS_ROOT}/public/404.html",  
        :status => 404
    end      
  end
  
  def authorize_for_user
    unless authorized?(User)
      render :file => "#{RAILS_ROOT}/public/404.html",  
        :status => 404
    end
  end
  
  
  
  # Refreshes the timeout for this session to be 
  # MAX_SESSION_PERIOD seconds from now, depending on the role
  # This should be done on every page request or refresh that a user does.
  def refresh_timeout
    session[:timeout] = current_user.class::SESSION_TIMEOUT.seconds.from_now
  end
  
  # Check if this current user's session has not yet expired.
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
