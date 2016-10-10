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

  # Checks user satisfies the following conditions:
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

      session[:redirect_uri] = request.fullpath  # save current uri

      # figure out how we want to explain this to users
      if session_expired?
        flash[:login_notice] = I18n.t("session_expired")
      else
        flash[:login_notice] = I18n.t("please_log_in")
      end

      if request.xhr? # is this an XMLHttpRequest?
        # Redirect users back to referer, or else
        # they might be redirected to an rjs page.
        session[:redirect_uri] = request.referer
        render nothing: true, status: :forbidden  # 403 http code
      else
        redirect_to controller: 'main', action: 'login'
      end
    end
  end

  # Helper method to check if current user is authorized given a
  # specific role.
  def authorize_only_for_admin
    unless authorized?(Admin)
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end

  def authorize_for_admin_and_admin_logged_in_as
    real_user = (session[:real_uid] && User.find_by_id(session[:real_uid])) ||
        nil
    unless authorized?(Admin) || (real_user && real_user.is_a?(Admin))
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end

  def authorize_for_ta_admin_and_reviewer(aid, result_id)
    result = Result.find(result_id)
    if aid == 'undefined'
      assignment = result.submission.assignment
    else
      assignment = Assignment.find(aid)
    end
    unless authorized?(Admin) || authorized?(Ta) ||
        (authorized?(Student) && assignment.has_peer_review_assignment? &&
            current_user.is_reviewer_for?(assignment.pr_assignment, result))
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end

  def authorize_for_ta_and_admin
    unless authorized?(Admin) || authorized?(Ta)
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end

  def authorize_for_student
    unless authorized?(Student)
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end

  def authorize_for_student_and_ta
    unless authorized?(Ta) || authorized?(Student)
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end

  def authorize_for_user
    unless authorized?(User)
      render 'shared/http_status', formats: [:html],
             locals:
                 { code: '404',
                   message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404, layout: false
    end
  end



  # Refreshes the timeout for this session to be
  # SESSION_TIMEOUT seconds from now, depending on the role
  # This should be done on every page request or refresh that a user does.
  def refresh_timeout
    session[:timeout] = current_user.class::SESSION_TIMEOUT.seconds.from_now
    session[:has_warned] = false
  end

  def set_warned
    session[:has_warned] = true
  end

  def check_warned
    session[:has_warned]
  end

  # Check if this current user's session has not yet expired.
  def session_expired?
    return true unless !session[:timeout].nil?
    if MarkusConfigurator.markus_config_remote_user_auth
      # expire session if there is not REMOTE_USER anymore.
      return true if @markus_auth_remote_user.nil?
      # If somebody switched role this state should be recorded
      # in the session. Expire only if session timed out.
      if !session[:real_uid].nil?
        # Roles have been switched, make sure that
        # real_user.user_name == @markus_auth_remote_user and
        # that the real user is in fact an admin.
        real_user = User.find_by_id(session[:real_uid])
        if real_user.user_name != @markus_auth_remote_user ||
           !real_user.admin?
          return true
        end
        # Otherwise, expire only if the session timed out.
        return session[:timeout] < Time.now
      end
      # Expire session if remote user does not match the session's uid.
      # We cannot have switched roles at this point.
      current_user = User.find_by_id(session[:uid])
      if !current_user.nil?
        return true if ( current_user.user_name != @markus_auth_remote_user )
      end
    end
    # No REMOTE_USER is involed.
    session[:timeout] < Time.now
  end

  def check_imminent_expiry
    if Time.parse(session[:timeout]) - Time.now <= 5.minutes
      return true
    end
    false
  end

  # Clear this current user's session set by this app
  def clear_session
    session[:timeout] = nil
    session[:uid] = nil
  end

end
