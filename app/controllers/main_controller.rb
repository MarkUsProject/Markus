
# Controller responsible for providing login and logout processes
# as well as displaying main page
class MainController < ApplicationController

  include MainHelper
  protect_from_forgery :except => [:login, :page_not_found]

  # check for authorization
  before_filter      :authorize_for_user,
                     :except => [:login,
                                 :page_not_found]

  #########################################################################
  # Authentication

  # Handles login requests; usually redirected here when trying to access
  # the website and has not logged in yet, or session has expired.  User
  # is redirected to main page if session is still active and valid.

  def login
    # external auth has been done, skip markus authorization
    if MarkusConfigurator.markus_config_remote_user_auth
      if @markus_auth_remote_user.nil?
        render :file => "#{RAILS_ROOT}/public/403.html",
          :status => 403
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

    @current_user = current_user
    # redirect to main page if user is already logged in.
    if logged_in? && !request.post?
      redirect_to :action => 'index'
      return
    end
    return unless request.post?

    # strip username
    params[:user_login].strip!
    
    #Get information of the user that is trying to login if his or her 
    #authentication is valid
    found_user = get_user(params[:user_login], params[:user_login], params[:user_password], :login_notice, 'login')
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

  #Returns the user with user name "login" from the database given that the user
  # with user name "login2" is authenticated. This function is called both by 
  # function login and login_as.
  def get_user(login, login2, password, notice, action)
    # check for blank username and password
    blank_login = login.blank?
    blank_pwd = password.blank?
    flash[notice] = get_blank_message(blank_login, blank_pwd)
    redirect_to(:action => action) && return if blank_login || blank_pwd

    # Two stage user verification: authentication and authorization
    authenticate_response = User.authenticate(login2, 
                                              password)
    if authenticate_response == User::AUTHENTICATE_BAD_PLATFORM
      flash[notice] = I18n.t("external_authentication_not_supported")
      return
    end
    if authenticate_response == User::AUTHENTICATE_SUCCESS
      # Username/password combination is valid. Check if user is
      # allowed to use MarkUs.
      #
      # sets this user as logged in if login is a user in MarkUs
      found_user = User.authorize(login) 
      # if not nil, user authorized to enter MarkUs
      if found_user.nil?
        # This message actually means "User not allowed to use MarkUs",
        # but it's from a security-perspective
        # not a good idea to report this to the outside world. It makes it
        # easier for attempted break-ins
        # if one can distinguish between existent and non-existent users.
        flash[notice] = I18n.t(:login_failed)
        return
      end
    else
      flash[notice] = I18n.t(:login_failed)
      return
    end

    return found_user
  end
  
  # Clear the sesssion for current user and redirect to login page
  def logout
    logout_redirect = MarkusConfigurator.markus_config_logout_redirect
    if logout_redirect == "NONE"
      page_not_found
      return
    end
    m_logger = MarkusLogger.instance

    #The real_uid field of session keeps track of the uid of the original
    # user that is logged in if there is a role switch
    if !session[:real_uid].nil? && !session[:uid].nil?
      #An admin was logged in as a student or grader
      m_logger.log("Admin '#{User.find_by_id(session[:real_uid]).get_user_name}' logged out from '#{User.find_by_id(session[:uid]).get_user_name}'.")
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
    render :action => 'index', :layout => 'content'
  end

  def about
    # dummy action for remote rjs calls
    # triggered by clicking on the about icon
  end

  def reset_api_key
    render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return unless request.post?
    # Students shouldn't be able to change their API key
    if !@current_user.student?
      @current_user.reset_api_key
      @current_user.save
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return
    end
    render :action => 'api_key_replace', :locals => {:user => @current_user }
  end

  # Render 404 error (page not found) if no other route matches.
  # See config/routes.rb
  def page_not_found
    render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
  end


#ROLE SWITCHING CODE
  #Calls view in order for the admin to login as a user with a "lesser" privileges
  def role_switching
  end

  #Authenticates the admin given the user that the admin will like to login as 
  # and the password of the admin
  def login_as

    #if the current user already recorded matches the password just entered in
    # grant the current user(admin) access to the account of the user name typed

    # check for blank admin password. We know the admin login name already so 
    #just pass that in

    found_user = get_user(params[:effective_user_login], params[:user_login], params[:admin_password], :role_switch_notice, 'role_switching')

    if found_user.nil?
      return 
    end

    #Check if an admin is trying to login as another admin. Should not be allowed   
    if found_user.admin?
      flash[:role_switch_notice] = I18n.t(:cannot_login_as_another_admin)
      redirect_to (:action => 'role_switching')
      return
    end
   
    #Log the admin that assumed the role of another user together with the time
    #and date that the role switch occurred
    m_logger = MarkusLogger.instance
    m_logger.log("Admin '#{current_user.user_name}' logged in as '#{params[:effective_user_login]}'.")

    #Save the uid of the admin that is switching roles
    session[:real_uid] = session[:uid]
    #Change the uid of the current user
    self.current_user = found_user

    if logged_in?
      uri = session[:redirect_uri]
      session[:redirect_uri] = nil
      refresh_timeout
      current_user.set_api_key # set api key in DB for user if not yet set
      # redirect to the main page of the viewer
      redirect_to(:action => 'index')
    else
      flash[:role_switch_notice] = I18n.t(:login_failed)
    end
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

    self.current_user = found_user

    if logged_in?
      return true
    else
      flash[:login_notice] = I18n.t(:login_failed)
      return false
    end
  end
end
