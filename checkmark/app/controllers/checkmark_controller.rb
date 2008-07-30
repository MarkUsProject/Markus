
# Controller responsible for providing login and logout processes 
# as well as displaying main page
class CheckmarkController < ApplicationController
  
  include CheckmarkHelper
  
  # exclude login/logout page so that anyone can access it (duh!)
  skip_before_filter :authenticate,   :only => [:login, :logout]

  
  # Handles login requests; usually redirected here when trying to access 
  # the website and has not logged in yet, or session has expired.  User 
  # is redirected to main page if session is still active and valid.
  def login
    # redirect to main page if user is already logged in.
    redirect_to :action => 'index' if logged_in?
    
    return unless request.post?
    
    # check for blank username and password
    blank_login = params[:user_login].blank?
    blank_pwd = params[:user_password].blank?
    flash[:login_notice] = get_blank_message(blank_login, blank_pwd)
    redirect_to(:action => 'login') && return if blank_login || blank_pwd
    
    # sets this user as logged in if login and password is valid
    self.current_user = User.authenticate(params[:user_login], params[:user_password])
    if logged_in?
      uri = session[:redirect_uri]
      session[:redirect_uri] = nil
      refresh_timeout
      # redirect to last visited page or to main page
      redirect_to(uri || { :action => 'index' })
    else
      flash[:login_notice] = "Your CDF login and password does not match."
    end
  end
  
  # Clear the sesssion for current user and redirect to login page
  def logout
    clear_session
    cookies.delete :auth_token
    reset_session
    redirect_to :action => 'login'
  end
  
  def index
    @user = self.current_user
  end

  
  # TODO refactor everything below; move to respective controllers
  
  def submit
    @task = { :title => 'Submit an Assignment', :action => 'submit' }
    
    # TODO the if cases here should be an action in a 'submit' controller
    unless params[:name].blank?
      assignment = Assignment.find_by_name(params[:name])
      @files = AssignmentFile.find(:all, 
        :conditions => ['assignment_id = ?', assignment.id], 
        :order => 'filename ASC')
    else
      # generate the assignment selection page for submitting assignment
      @assignments = Assignment.find(:all)
      render :action => 'assignments'
    end
  end
  
  # 
  
end
