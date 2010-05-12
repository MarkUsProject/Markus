require File.dirname(__FILE__) + '/authenticated_controller_test'

# re-raise errors caught by controller
class MainController; def rescue_action(e) raise e end; end

class MainControllerTest < AuthenticatedControllerTest
  
  fixtures :all
  
  # TODO need to change username and password for valid logins when 
  # actual authentication is in place (i.e. when User.verify is implemented)
  
  def setup
    @controller = MainController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  # Test if users not logged in and trying to access other pages 
  # are being redirected to login page.
  def test_redirect
    get :index
    assert_redirected_to :action => "login", :controller => "main"
    assert_not_equal "", flash[:login_notice]
  end
  
  # Test if users see an error regarding missing information on login
  def test_blank_login_and_pwd
    get :login
    post :login, :user_login => "", :user_password => ""
    assert_not_equal "", flash[:login_notice] 
  end
  
  # Test if users see an error regarding missing information on login
  def test_blank_login
    get :login
    post :login, :user_login => "", :user_password => "afds"
    assert_equal I18n.t(:username_not_blank), flash[:login_notice]
  end
  
  # Test if users see an error regarding missing information on login
  def test_blank_pwd
    get :login
    post :login, :user_login => "afds", :user_password => ""
    assert_equal I18n.t(:password_not_blank), flash[:login_notice]
  end
  
  # Test if users with valid username and password can login and that 
  # session parameters has been correctly set
  def test_correct_login
    admin = users(:olm_admin_1)
    post :login, :user_login => admin.user_name, :user_password => 'asfd'
    assert_equal "", flash[:login_notice]
    assert_redirected_to :action => "index"
    assert_equal admin.id, session[:uid]
    assert_not_nil session[:timeout]
  end
  
  # Test when user fails to validate and correctly tries again
  def test_second_try
    admin = users(:olm_admin_1)
    post :login, :user_login => "afds", :user_password => "lala"
    assert_equal I18n.t(:login_failed), flash[:login_notice]
    
    post :login, :user_login => admin.user_name, :user_password => "lala"
    assert_redirected_to :action => "index"
    assert_equal admin.id, session[:uid]
  end
  
  # Test if logging out redirects user to login page and clears session
  def test_logout
    student = users(:student1)
    post :login, :user_login => student.user_name, :user_password => "lala"
    assert_redirected_to :action => "index"
    get :logout
    assert_redirected_to :action => "login"
    assert_nil session[:uid]
    assert_nil session[:timeout]
    
    # try to go back to a page
    get :index
    assert_redirected_to :action => "login", :controller => "main"
  end
  
  # Test if users are redirected to main page 
  # if they are already logged in.
  def test_redirect_logged_in
    # log in
    admin = users(:olm_admin_1)
    post :login, :user_login => admin.user_name, :user_password => 'asfd'
    assert_redirected_to :action => "index"
    
    # try to go to login page when logged in
    get :login
    assert_redirected_to :action => "index"
  end
  
  def test_index
    user = users(:student1)
    get_as user, :index
    assert_redirected_to :controller => 'assignments', :action => 'index'
  end
    
end
