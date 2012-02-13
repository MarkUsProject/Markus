require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'
require 'machinist'

# re-raise errors caught by controller
class MainController
  def rescue_action(e)
    raise e
  end
end

class MainControllerTest < AuthenticatedControllerTest

  # TODO need to change username and password for valid logins when
  # actual authentication is in place (i.e. when User.verify is implemented)

  def setup
    clear_fixtures
    # bypass cookie detection in the test because the command line, which is running the test, cannot accept cookies
    @request.cookies["cookieTest"] = "fake cookie bypasses filter"
  end

  context "A not authenticated user" do
    should "be redirected to login" do
      get :index
      assert_redirected_to :action => "login", :controller => "main"
      assert_not_equal "", flash[:login_notice]
    end

    should "should not be able to log in without login and password" do
      post :login, :user_login => "", :user_password => ""
      assert_not_equal "", flash[:login_notice]
    end

    should "should not be able to log in with a blank login" do
      get :login
      post :login, :user_login => "", :user_password => "afds"
      assert_equal I18n.t(:username_not_blank), flash[:login_notice]
    end

    should "should not be able to log in with a blank password" do
      get :login
      post :login, :user_login => "afds", :user_password => ""
      assert_equal I18n.t(:password_not_blank), flash[:login_notice]
    end
  end

  context "An admin" do
    setup do
      @admin = Admin.make
    end

    should "be able to login" do
      post :login,
           :user_login => @admin.user_name,
           :user_password => 'asfd'
      # on successful logins there shouldn't be a :login_notice
      # in the flash
      assert_equal nil, flash[:login_notice]
      assert_redirected_to :action => "index"
      assert_equal @admin.id, session[:uid]
      assert_not_nil session[:timeout]
    end

    should "not be able to login with wrong username" do
      post :login, :user_login => "afds", :user_password => "lala"
      assert_equal I18n.t(:login_failed), flash[:login_notice]
    end

    # Test if logging out redirects user to login page and clears session
    should "be able to log out" do
      post :login,
           :user_login => @admin.user_name,
           :user_password => "lala"
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
    should "be redirected to main page if already logged in" do
      get_as @admin, :login
      assert_redirected_to :action => "index"
    end

    should "be able to reset his API key" do
      admin_key = @admin.api_key
      post_as @admin, :reset_api_key, {:current_user => @admin}

      assert_response :success
      @admin.reload
      assert_not_equal(User.find_by_id(@admin.id).api_key, admin_key)
    end

    should "not do anything when doing a get on reset_api_key " do
      admin_key = @admin.api_key
      get_as @admin, :reset_api_key
      assert_response :not_found
      assert_equal @admin.api_key, admin_key
    end


  end

  context "A student" do
    setup do
      @student = Student.make
    end

    should "be redirected to assignments controller" do
      get_as @student, :index
      assert_redirected_to :controller => 'assignments', :action => 'index'
    end
  end

end
