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
      if @real_user.admin_user?
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
    if cookies.encrypted[:lti_redirect].present?
      redirect_url = cookies.encrypted[:lti_redirect]
      cookies.delete(:lti_redirect)
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
  def page_not_found # rubocop:disable Lint/UselessMethodDefinition
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
  #
  def validate_login(user_name, password)
    if user_name.blank? || password.blank?
      flash_now(:error, get_blank_message(user_name, password))
      return false
    end

    # No validate file means only remote authentication is allowed
    return false unless Settings.validate_file

    ip = Settings.validate_ip ? request.remote_ip : nil
    authenticate_response = User.authenticate(user_name, password, ip: ip)
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
