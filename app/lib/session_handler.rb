# Responsible for maintaining sessions and querying session status
# All controllers are expected to extend this module (already by default)
module SessionHandler
  protected

  # Sets current user for this session
  def current_user=(user)
    session[:user_name] = user.is_a?(User) ? user.user_name : nil
  end

  def real_user=(user)
    session[:real_user_name] = user.is_a?(User) ? user.user_name : nil
  end

  # Retrieve current user for this session, or nil if none exists
  def current_user
    # retrieve from database on every request instead of
    # storing it as global variable when current_user=
    # is called to prevent user information becoming stale.
    @current_user ||= (session[:user_name] && User.find_by(user_name: session[:user_name])) || real_user
  end

  def real_user
    return @real_user if defined? @real_user
    real_user_name = remote_auth? ? remote_user_name : session[:real_user_name]
    @real_user = User.find_by(user_name: real_user_name) if real_user_name
  end

  def current_role
    return @current_role if defined? @current_role
    if current_course.nil?
      @current_role = nil
    elsif current_user&.admin_user?
      @current_role = AdminRole.find_or_create_by(user: current_user, course: current_course)
    else
      @current_role = Role.find_by(user: current_user, course: current_course, hidden: false)
    end
  end

  def real_role
    return @real_role if defined? @real_role
    if current_course.nil?
      @real_role = nil
    elsif real_user&.admin_user?
      @real_role = AdminRole.find_or_create_by(user: real_user, course: current_course)
    else
      @real_role = Role.find_by(user: real_user, course: current_course, hidden: false)
    end
  end

  def current_course
    @current_course ||= if controller_name == 'courses'
                          record
                        else
                          parent_records.select { |r| r.is_a? Course }.first
                        end
  end

  # Returns the record specified by params[:id]
  def record
    @record ||= if request.path_parameters[:id]
                  controller_name.classify.constantize.find_by(id: request.path_parameters[:id])
                end
  end

  # When the current route is a nested route, get the parameters whose name matches *_id.
  def parent_params
    request.path_parameters.keys.select { |k| k.end_with?('_id') }
  end

  def parent_records
    @parent_records ||= parent_params.map do |key|
      key.to_s.delete_suffix('_id').classify.constantize.find_by(id: params[key])
    end
  end

  # Render a 404 error if a record or parent_records are expected to exist but does not because a non-existant id was
  # passed as a parameter. Also renders a 404 if any of the records is not associated with the current course
  #
  # Note: his does not check if the record and parent_records are actually associated to each other when a parent record
  # is not a Course. Because of this, non-shallow routes should check those associations themselves and render a 404
  # error if needed.
  def check_record
    return page_not_found if request.path_parameters[:id] && record.nil?
    return page_not_found if parent_params.length != parent_records.compact.length
    page_not_found if [record, *parent_records].compact
                                               .reject { |r| r.is_a? Course }
                                               .any? { |r| r.try(:course) != current_course }
  end

  # Check if there's any user associated with this session
  def logged_in?
    !real_user.nil?
  end

  def remote_user_name
    @remote_user_name ||= request.env['HTTP_X_FORWARDED_USER']
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
    if logged_in? && !session_expired?
      refresh_timeout
    else
      remote_login_error = remote_auth? && remote_user_name
      clear_session
      if remote_login_error
        flash_message(:error,
                      I18n.t('main.external_authentication_user_not_found',
                             name: Settings.remote_auth_login_name ||
                                   I18n.t('main.external_authentication_default_name')))
      end
      if request.xhr? # is this an XMLHttpRequest?
        # Redirect users back to referer, or else
        # they might be redirected to an rjs page.
        session[:redirect_uri] = request.referer
        head :forbidden # 403
      else
        session[:redirect_uri] = request.fullpath
        redirect_to root_path
      end
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
    return remote_user_name.nil? if remote_auth?
    return true if session[:timeout].nil?

    Time.zone.parse(session[:timeout]) < Time.current
  end

  def check_imminent_expiry
    return false if remote_auth?
    !session[:timeout].nil? && (Time.zone.parse(session[:timeout]) - Time.current) <= 5.minutes
  end

  # Clear this current user's session set by this app
  def clear_session
    session[:timeout] = nil
    session[:user_name] = nil
    session[:real_user_name] = nil
    session[:job_id] = nil
    session[:auth_type] = nil
    cookies.delete :auth_token
    reset_session
  end

  def remote_auth?
    session[:auth_type] == 'remote'
  end
end
