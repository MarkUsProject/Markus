# Controller responsible for providing login and logout processes
# as well as displaying main page
class MainController < ApplicationController
  include ApplicationHelper

  protect_from_forgery with: :exception, except: [:login, :page_not_found]

  # check for authorization
  skip_before_action :check_course_switch, only: [:login, :page_not_found, :check_timeout, :login_remote_auth, :about,
                                                  :logout]
  authorize :real_user, through: :real_user
  before_action(except: [:login, :page_not_found, :check_timeout, :login_remote_auth]) { authorize! }
  skip_verify_authorized only: [:login, :page_not_found, :check_timeout, :login_remote_auth]

  layout 'main'

  #########################################################################
  # Authentication

  # Handles login requests; usually redirected here when trying to access
  # the website and has not logged in yet, or session has expired.  User
  # is redirected to main page if session is still active and valid.
  def login
    # redirect to main page if user is already logged in.
    if logged_in? && !request.post?
      if remote_auth? && Settings.remote_validate_file && !validate_login(request.env['HTTP_X_FORWARDED_USER'], '',
                                                                          auth_type: User::AUTHENTICATE_REMOTE)
        logout
        flash_message(:error, I18n.t('main.external_authentication_bad_ip',
                                     name: Settings.remote_auth_login_name ||
                                       I18n.t('main.external_authentication_default_name')))
        return
      end
      if cookies.encrypted[:lti_data].present?
        lti_data = JSON.parse(cookies.encrypted[:lti_data]).symbolize_keys
        redirect_url = lti_data.fetch(:lti_redirect, root_url)
        redirect_to redirect_url
      elsif @real_user.admin_user?
        redirect_to(admin_path)
      elsif allowed_to?(:role_is_switched?)
        redirect_to course_assignments_path(session[:role_switch_course_id])
      else
        redirect_to(courses_path)
      end
      return
    end
    unless Settings.remote_auth_login_url || Settings.validate_file
      flash_now(:error, t('main.sign_in_not_supported'))
    end
    if remote_auth? && remote_user_name
      flash_message(:error,
                    I18n.t('main.external_authentication_user_not_found',
                           name: Settings.remote_auth_login_name ||
                                 I18n.t('main.external_authentication_default_name')))
    end
    return unless request.post?

    # Get information of the user that is trying to login if his or her
    # authentication is valid
    unless validate_login(params[:user_login], params[:user_password])
      render :login, locals: { user_login: params[:user_login] }
      return
    end

    session[:auth_type] = 'local'

    found_user = User.find_by(user_name: params[:user_login])
    if found_user.nil? || !(found_user.admin_user? || found_user.end_user?)
      flash_now(:error, Settings.validate_user_not_allowed_message || I18n.t('main.login_failed'))
      render :login, locals: { user_login: params[:user_login] }
      return
    end

    self.real_user = found_user

    uri = session[:redirect_uri]
    session[:redirect_uri] = nil
    refresh_timeout
    # redirect to last visited page or to main page
    if cookies.encrypted[:lti_data].present?
      lti_data = JSON.parse(cookies.encrypted[:lti_data]).symbolize_keys
      redirect_url = lti_data.key?(:lti_redirect) ? lti_data[:lti_redirect] : root_url
      redirect_to redirect_url
    elsif uri.present?
      redirect_to(uri)
    elsif found_user.admin_user?
      redirect_to(admin_path)
    else
      redirect_to(courses_path)
    end
  end

  def login_remote_auth
    session[:auth_type] = 'remote'
    redirect_to Settings.remote_auth_login_url, allow_other_host: true
  end

  # Clear the sesssion for current user and redirect to login page
  def logout
    logout_redirect = Settings.logout_redirect
    if logout_redirect == 'NONE'
      page_not_found
      return
    end
    MarkusLogger.instance.log("User '#{real_user.user_name}' logged out.")
    clear_session
    if logout_redirect == 'DEFAULT'
      redirect_to action: 'login'
    else
      redirect_to logout_redirect
    end
  end

  def about
    # dummy action for remote rjs calls
    # triggered by clicking on the about icon
  end

  # Render 404 error (page not found) if no other route matches.
  # See config/routes.rb
  def page_not_found
    super
  end

  def check_timeout
    head :ok unless check_imminent_expiry
  end

  def refresh_session
    refresh_timeout
    head :ok
  end

  private

  # Returns the user with user name "effective_user" from the database given that the user
  # with user name "real_user" is authenticated. Effective and real users might be the
  # same for regular logins and are different on an assume role call.
  # If the login keyword is true then this method also authenticates the real_user
  # If auth_type == User::AUTHENTICATE_LOCAL, the real_user will be authenticated against their password
  # If auth_type == User::AUTHENTICATE_REMOTE, the real_user will be authenticated against their
  # user_name. if Settings.validate_ip is true, the user's ip address will also be validated
  def validate_login(user_name, password, auth_type: User::AUTHENTICATE_LOCAL)
    if user_name.blank? || (password.blank? && auth_type == User::AUTHENTICATE_LOCAL)
      flash_now(:error, get_blank_message(user_name, password))
      return false
    end

    # Validate locally or by user_name for remote authentication.
    # If there is no validate_file, only remote authentication is allowed
    return false unless Settings.validate_file || Settings.remote_validate_file

    ip = Settings.validate_ip ? request.remote_ip : nil
    authenticate_response = User.authenticate(user_name, password: password, ip: ip, auth_type: auth_type)
    custom_status = Settings.validate_custom_status_message[authenticate_response]

    if authenticate_response == User::AUTHENTICATE_BAD_PLATFORM
      flash_now(:error, I18n.t('main.external_authentication_not_supported'))
    elsif custom_status
      flash_now(:error, custom_status)
    elsif authenticate_response == User::AUTHENTICATE_SUCCESS
      return true
    else
      flash_now(:error, Settings.incorrect_login_message || I18n.t('main.login_failed'))
    end
    false
  end

  def get_blank_message(login, password)
    if login.blank? && password.blank?
      I18n.t('main.username_and_password_not_blank')
    elsif login.blank?
      I18n.t('main.username_not_blank')
    elsif password.blank?
      I18n.t('main.password_not_blank')
    end
  end

  protected

  def implicit_authorization_target
    OpenStruct.new policy_class: MainPolicy
  end
end
