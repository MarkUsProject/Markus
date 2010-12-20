
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
        render :file => "#{::Rails.root.to_s}/public/403.html",
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

    # check for blank username and password
    blank_login = params[:user_login].blank?
    blank_pwd = params[:user_password].blank?
    flash[:login_notice] = get_blank_message(blank_login, blank_pwd)
    redirect_to(:action => 'login') && return if blank_login || blank_pwd

    # Two stage user verification: authentication and authorization
    authenticate_response = User.authenticate(params[:user_login], 
                                              params[:user_password])
    if authenticate_response == User::AUTHENTICATE_BAD_PLATFORM
      flash[:login_notice] = I18n.t("external_authentication_not_supported")
      return
    end
    if authenticate_response == User::AUTHENTICATE_SUCCESS
      # Username/password combination is valid. Check if user is 
      # allowed to use MarkUs.
      #
      # sets this user as logged in if login is a user in MarkUs
      found_user = User.authorize(params[:user_login]) 
      # if not nil, user authorized to enter MarkUs
      if found_user.nil?
        # This message actually means "User not allowed to use MarkUs", 
        # but it's from a security-perspective
        # not a good idea to report this to the outside world. It makes it 
        # easier for attempted break-ins
        # if one can distinguish between existent and non-existent users.
        flash[:login_notice] = I18n.t(:login_failed)
        return
      end
    else
      flash[:login_notice] = I18n.t(:login_failed)
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
    m_logger.log("User '#{current_user.user_name}' logged out.")

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
    render :file => "#{::Rails.root.to_s}/public/404.html", :status => 404 and return unless request.post?
    # Students shouldn't be able to change their API key
    if !@current_user.student?
      @current_user.reset_api_key
      @current_user.save
    else
      render :file => "#{::Rails.root.to_s}/public/404.html", :status => 404 and return
    end
    render :action => 'api_key_replace', :locals => {:user => @current_user }
  end

  # Render 404 error (page not found) if no other route matches.
  # See config/routes.rb
  def page_not_found
    render :file => "#{::Rails.root.to_s}/public/404.html", :status => 404
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
