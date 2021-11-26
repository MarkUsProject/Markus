# Responsible for maintaining sessions and querying session status
# All controllers are expected to extend this module (already by default)
module SessionHandler

  protected

  # Sets current user for this session
  def current_user=(user)
    session[:user_name] = user&.is_a?(User) ? user.user_name : nil
  end

  def real_user=(user)
    session[:real_user_name] = user&.is_a?(User) ? user.user_name : nil
  end

  # Retrieve current user for this session, or nil if none exists
  def current_user
    # retrieve from database on every request instead of
    # storing it as global variable when current_user=
    # is called to prevent user information becoming stale.
    @current_user ||= (session[:user_name] && User.find_by_user_name(session[:user_name])) || real_user
  end

  def real_user
    @real_user ||= session[:real_user_name] && User.find_by_user_name(session[:real_user_name])
  end

  def current_role
    @current_role ||= Role.find_by(human: current_user, course: current_course)
  end

  def real_role
    @real_role ||= Role.find_by(human: real_user, course: current_course)
  end

  def current_course
    if controller_name == 'courses' && action_name == 'index'
      @current_course = nil
    elsif controller_name == 'courses'
      @current_course ||= Course.find_by(id: params[:id])
    else
      @current_course ||= Course.find_by(id: params[:course_id])
    end
  end

  # Check if there's any user associated with this session
  def logged_in?
    !session[:real_user_name].nil?
  end

  def remote_user_name
    @remote_user_name ||= if request.env['HTTP_X_FORWARDED_USER'].present?
                            request.env['HTTP_X_FORWARDED_USER']
                          elsif Settings.remote_user_auth && !Rails.env.production?
                            # This is only used in non-production modes to test Markus behaviours specific to
                            # external authentication. This should not be used in the place of any real
                            # authentication (basic or otherwise)!
                            authenticate_or_request_with_http_basic { |username, _| username }
                          end
  end

  def redirect_to_last_page
    uri = session[:redirect_uri]
    session[:redirect_uri] = nil
    redirect_to(uri || { action: 'index' })
  end

  # Checks user satisfies the following conditions:
  # => User has an active session and is not expired
  # => User has privilege to view the page/perform action
  # If not, then user is redirected to login page for authentication.
  def authenticate
    if Settings.remote_user_auth
      if remote_user_name.nil?
        msg = Settings.validate_user_not_allowed_message || I18n.t('main.login_failed')
        render :remote_user_auth_login_fail, status: 403, locals: { login_error: msg }
      else
        refresh_timeout
        session[:real_user_name] = remote_user_name
      end
    elsif real_user.nil? || session_expired?
      # cleanup expired session stuff
      clear_session
      if request.xhr? # is this an XMLHttpRequest?
        # Redirect users back to referer, or else
        # they might be redirected to an rjs page.
        session[:redirect_uri] = request.referer
        head :forbidden # 403
      else
        session[:redirect_uri] = request.fullpath
        redirect_to controller: 'main', action: 'login'
      end
    else
      refresh_timeout
    end
  end

  # Refreshes the timeout for this session to be
  # SESSION_TIMEOUT seconds from now, depending on the role
  # This should be done on every page request or refresh that a user does.
  def refresh_timeout
    # a json session cookie will serialize time as strings, make the conversion explicit so that tests too see strings
    # (see config.action_dispatch.cookies_serializer)
    session[:timeout] = Settings.session_timeout.seconds.from_now.to_s
    session[:has_warned] = false
  end

  # Check if this current user's session has not yet expired.
  def session_expired?
    return true if session[:timeout].nil?

    Time.zone.parse(session[:timeout]) < Time.current
  end

  def check_imminent_expiry
    !session[:timeout].nil? && (Time.zone.parse(session[:timeout]) - Time.current) <= 5.minutes
  end

  # Clear this current user's session set by this app
  def clear_session
    session[:timeout] = nil
    session[:user_name] = nil
    session[:real_user_name] = nil
    session[:job_id] = nil
    cookies.delete :auth_token
    reset_session
  end

end
