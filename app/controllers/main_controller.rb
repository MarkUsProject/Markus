
# Controller responsible for providing login and logout processes
# as well as displaying main page
class MainController < ApplicationController

  include MainHelper
  include CookieDetection

  protect_from_forgery :except => [:login, :page_not_found]

  # check for authorization
  before_filter      :authorize_for_user,
                     :except => [:login,
                                 :page_not_found]
  before_filter :authorize_only_for_admin, :only => [:login_as]

  #########################################################################
  # Authentication

  # Handles login requests; usually redirected here when trying to access
  # the website and has not logged in yet, or session has expired.  User
  # is redirected to main page if session is still active and valid.

  def login

    # external auth has been done, skip markus authorization
    if MarkusConfigurator.markus_config_remote_user_auth
      if @markus_auth_remote_user.nil?
        render 'shared/http_status.html', :locals => { :code => "403", :message => HttpStatusHelper::ERROR_CODE["message"]["403"] }, :status => 403, :layout => false
        return
      else
        login_success = login_without_authentication(@markus_auth_remote_user)
        if login_success
          uri = session[:redirect_uri]
          session[:redirect_uri] = nil
          refresh_timeout
          current_user.set_api_key # set api key in DB for user if not yet set
          # redirect to last visited page or to main page
          redirect_to( uri || { :action => 'index' } )
          return
        else
          @login_error = flash[:login_notice]
          render :remote_user_auth_login_fail
          return
        end
      end
    end

    # check cookies
    if !cookies_enabled
      flash[:login_notice] = I18n.t(:cookies_off)
      return
    end

    @current_user = current_user
    # redirect to main page if user is already logged in.
    if logged_in? && !request.post?
      redirect_to :action => 'index'
      return
    end
    return unless request.post?

    # strip username
    params[:user_login].strip!

    # Get information of the user that is trying to login if his or her
    # authentication is valid
    validation_result = validate_user(params[:user_login], params[:user_login], params[:user_password])
    if !validation_result[:error].nil?
      flash[:login_notice] = validation_result[:error]
      redirect_to :action => 'login'
      return
    end
    # validation worked
    found_user = validation_result[:user]
    if found_user.nil?
      return
    end

    # Has this student been hidden?
    if found_user.student? && found_user.hidden
      flash[:login_notice] = I18n.t("account_disabled")
      redirect_to(:action => 'login') && return
    end

    self.current_user = found_user

    if logged_in?
      uri = session[:redirect_uri]
      session[:redirect_uri] = nil
      refresh_timeout
      current_user.set_api_key # set api key in DB for user if not yet set
      # redirect to last visited page or to main page
      redirect_to( uri || { :action => 'index' } )
    else
      flash[:login_notice] = I18n.t(:login_failed)
    end
  end


  # Clear the sesssion for current user and redirect to login page
  def logout
    logout_redirect = MarkusConfigurator.markus_config_logout_redirect
    if logout_redirect == "NONE"
      page_not_found
      return
    end
    m_logger = MarkusLogger.instance

    # The real_uid field of session keeps track of the uid of the original
    # user that is logged in if there is a role switch
    if !session[:real_uid].nil? && !session[:uid].nil?
      #An admin was logged in as a student or grader
      m_logger.log("Admin '#{User.find_by_id(session[:real_uid]).user_name}' logged out from '#{User.find_by_id(session[:uid]).user_name}'.")
    else
      #The user was not assuming another role
      m_logger.log("User '#{current_user.user_name}' logged out.")
    end
    clear_session
    cookies.delete :auth_token
    reset_session
    if logout_redirect == 'DEFAULT'
      redirect_to :action => 'login'
      return
    else
      redirect_to logout_redirect
      return
    end
  end

  def index
    @current_user = current_user
    if @current_user.student? or @current_user.ta?
      redirect_to :controller => 'assignments', :action => 'index'
      return
    end
    @assignments = Assignment.find(:all)
    render :index, :layout => 'content'
  end

  def about
    # dummy action for remote rjs calls
    # triggered by clicking on the about icon
  end

  def reset_api_key
    render 'shared/http_status.html', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404, :layout => false and return unless request.post?
    # Students shouldn't be able to change their API key
    if !@current_user.student?
      @current_user.reset_api_key
      @current_user.save
    else
      render 'shared/http_status.html', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404, :layout => false and return
    end
    render :api_key_replace, :locals => {:user => @current_user }
  end

  # Render 404 error (page not found) if no other route matches.
  # See config/routes.rb
  def page_not_found
    render 'shared/http_status.html', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404, :layout => false
  end

  # Authenticates the admin (i.e. validates her password). Given the user, that
  # the admin would like to login as and the admin's password switch to the
  # desired user on success.
  #
  # If the current user already recorded, matches the password entered in the
  # form, grant the current user (an admin) access to the account of the user
  # name entered in the form.
  #
  # Relevant partials:
  #   role_switch_handler
  #   role_switch_error
  #   role_switch_content
  #   role_switch
  def login_as
    validation_result = nil
    if MarkusConfigurator.markus_config_remote_user_auth
      validation_result = validate_user_without_login(params[:effective_user_login],
                                        params[:user_login])
    else
      validation_result = validate_user(params[:effective_user_login],
                                        params[:user_login],
                                        params[:admin_password])
    end
    if !validation_result[:error].nil?
      # There were validation errors
      render :partial => "role_switch_handler",
        :locals => { :error => validation_result[:error], :success => false }
      return
    end

    found_user = validation_result[:user]
    if found_user.nil?
      return
    end

    # Check if an admin is trying to login as another admin. Should not be allowed
    if found_user.admin?
      # error
      render :partial => "role_switch_handler", :locals =>
            { :error => I18n.t(:cannot_login_as_another_admin), :success => false }
      return
    end

    # Log the admin that assumed the role of another user together with the time
    # and date that the role switch occurred
    m_logger = MarkusLogger.instance
    m_logger.log("Admin '#{current_user.user_name}' logged in as '#{params[:effective_user_login]}'.")

    # Save the uid of the admin that is switching roles
    session[:real_uid] = session[:uid]
    # Change the uid of the current user
    self.current_user = found_user

    if logged_in?
      uri = session[:redirect_uri]
      session[:redirect_uri] = nil
      refresh_timeout
      current_user.set_api_key # set api key in DB for user if not yet set
      # All good, redirect to the main page of the viewer, discard
      # role switch modal
      render :partial => "role_switch_handler", :locals =>
            { :success => true }
      return
    else
      render :partial => "role_switch_handler", :locals =>
            { :error => I18n.t(:login_failed), :success => false }
      return
    end
  end

  def role_switch
    # dummy action for remote rjs calls
    # triggered by clicking on the "Switch role" link
    # please keep.
  end

  # Action only relevant if REMOTE_USER config is on and if an
  # admin switched role. Since there might not be a logout link
  # provide a vehicle to expire the session (I.e. cancel the
  # role switch).
  def clear_role_switch_session
    m_logger = MarkusLogger.instance

    # The real_uid field of session keeps track of the uid of the original
    # user that is logged in if there is a role switch
    if !session[:real_uid].nil? && !session[:uid].nil?
      # An admin was logged in as a student or grader
      m_logger.log("Admin '#{User.find_by_id(session[:real_uid]).user_name}' logged out from '#{User.find_by_id(session[:uid]).user_name}'.")
    else
      #The user was not assuming another role
      m_logger.log("WARNING: Possible break in attempt from '#{current_user.user_name}'.")
    end
    clear_session
    cookies.delete :auth_token
    reset_session
    redirect_to :action => 'login'
    return
  end

private

  def login_without_authentication(markus_auth_remote_user)
    found_user = User.authorize(markus_auth_remote_user)
    # if not nil, user authorized to enter MarkUs
    if found_user.nil?
      # This message actually means "User not allowed to use MarkUs",
      # but it's from a security-perspective
      # not a good idea to report this to the outside world. It makes it
      # easier for attempted break-ins
      # if one can distinguish between existent and non-existent users.
      flash[:login_notice] = I18n.t(:login_failed)
      return false
    end

    # Has this student been hidden?
    if found_user.student? && found_user.hidden
      flash[:login_notice] = I18n.t("account_disabled")
      return false
    end

    # For admins we have a possibility of role switches,
    # so check if the real_uid is set in the session.
    if found_user.admin? && !session[:real_uid].nil? &&
       session[:real_uid] != session[:uid]
      self.current_user = User.find_by_id(session[:uid])
      m_logger = MarkusLogger.instance
      m_logger.log("Admin '#{found_user.user_name}' logged in as '#{current_user.user_name}'.")
    else
      self.current_user = found_user
    end

    if logged_in?
      return true
    else
      flash[:login_notice] = I18n.t(:login_failed)
      return false
    end
  end

  # Returns the user with user name "effective_user" from the database given that the user
  # with user name "real_user" is authenticated. Effective and real users might be the
  # same for regular logins and are different on an assume role call.
  #
  # This function is called both by the login and login_as actions.
  def validate_user(effective_user, real_user, password)
    validation_result = Hash.new
    validation_result[:user] = nil # Let's be explicit
    # check for blank username and password
    blank_login = effective_user.blank?
    blank_pwd = password.blank?
    validation_result[:error] = get_blank_message(blank_login, blank_pwd)
    return validation_result if blank_login || blank_pwd

    # Two stage user verification: authentication and authorization
    authenticate_response = User.authenticate(real_user,
                                              password)
    if authenticate_response == User::AUTHENTICATE_BAD_PLATFORM
      validation_result[:error] = I18n.t("external_authentication_not_supported")
      return validation_result
    end
    if authenticate_response == User::AUTHENTICATE_SUCCESS
      # Username/password combination is valid. Check if user is
      # allowed to use MarkUs.
      #
      # sets this user as logged in if effective_user is a user in MarkUs
      found_user = User.authorize(effective_user)
      # if not nil, user authorized to enter MarkUs
      if found_user.nil?
        # This message actually means "User not allowed to use MarkUs",
        # but it's from a security-perspective
        # not a good idea to report this to the outside world. It makes it
        # easier for attempted break-ins
        # if one can distinguish between existent and non-existent users.
        validation_result[:error] = I18n.t(:login_failed)
        return validation_result
      end
    else
      validation_result[:error] = I18n.t(:login_failed)
      return validation_result
    end

    # All good, set error to nil. Let's be explicit.
    # Also, set the user key to found_user
    validation_result[:error] = nil
    validation_result[:user] = found_user
    return validation_result
  end

  # Returns the user with user name "effective_user" from the database given that the user
  # with user name "real_user" is authenticated. Effective and real users must be
  # different.
  def validate_user_without_login(effective_user, real_user)
    validation_result = Hash.new
    validation_result[:user] = nil # Let's be explicit
    # check for blank username
    blank_login = effective_user.blank?
    validation_result[:error] = get_blank_message(blank_login, false)
    return validation_result if blank_login

    # Can't do user authentication, for a remote user setup, so
    # only do authorization (i.e. valid user) checks.
    found_user = User.authorize(effective_user)
    # if not nil, user authorized to enter MarkUs
    if found_user.nil?
      # This message actually means "User not allowed to use MarkUs",
      # but it's from a security-perspective
      # not a good idea to report this to the outside world. It makes it
      # easier for attempted break-ins
      # if one can distinguish between existent and non-existent users.
      validation_result[:error] = I18n.t(:login_failed)
      return validation_result
    end

    # All good, set error to nil. Let's be explicit.
    # Also, set the user key to found_user
    validation_result[:error] = nil
    validation_result[:user] = found_user
    return validation_result
  end

end
