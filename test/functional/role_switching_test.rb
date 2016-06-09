require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require 'shoulda'
require 'machinist'

class RoleSwitchingTest < AuthenticatedControllerTest

  # Required for REMOTE_USER config mocking
  include MarkusConfigurator

  def setup
    # bypass cookie detection in the test because the command line, which is running the test, cannot accept cookies
    @request.cookies['cookieTest'] = 'fake cookie bypasses filter'
  end

  context 'A valid admin' do
    setup do
      # Tests apply to  main controller
      @controller = MainController.new
      @admin = Admin.make
      @student = Student.make
      post :login, user_login: @admin.user_name, user_password: 'asfd'
    end

    should 'be able to log in and the session uid is correctly set' do
      assert_equal @admin.id, session[:uid]
    end

    context 'and providing empty data for effective user' do
      setup do
        assert_equal @admin.id, session[:uid]
        post_as @admin, :login_as, effective_user_login: '',
          user_login: @admin.user_name, admin_password: 'adfadsf'
      end

      should 'NOT switch role' do
        assert_nil session[:real_uid]
      end
    end

    context 'and providing empty data for the password' do
      setup do
        assert_equal @admin.id, session[:uid]
        post_as @admin, :login_as, effective_user_login: @student.user_name,
          user_login: @admin.user_name, admin_password: ""
      end

      should 'NOT switch role' do
        assert_nil session[:real_uid]
      end
    end

    context 'and attempting to switch to another admin' do
      setup do
        assert_equal @admin.id, session[:uid]
        post_as @admin, :login_as, effective_user_login: @admin.user_name,
          user_login: @admin.user_name, admin_password: 'lasdfj'
      end

      should 'NOT switch role' do
        assert_nil session[:real_uid]
      end
    end

    context 'when logged in' do
      setup do
        assert_equal @admin.id, session[:uid]
        @response = post_as @admin, :login_as, effective_user_login: @student.user_name,
          user_login: @admin.user_name, admin_password: 'adfadsf'
      end

      should render_template '_role_switch_handler'

      should 'be able to switch to a role with lesser privileges' do
        # redirect is done by JS, so match that we get a response
        # window.location.href = <index_url>
        assert redirect_to action: 'index'
        # should have set real_uid in the session
        assert_equal @admin.id , session[:real_uid]
        assert_not_equal session[:uid], session[:real_uid]
        assert_not_nil session[:timeout]
      end

      context 'when having switched roles' do
        setup do
          get_as @admin, :logout
        end

        should redirect_to action: 'login'

        should 'be able to log out and session info is discarded' do
          assert_nil session[:real_uid]
          assert_nil session[:uid]
        end
      end

    end
  end

  # Student login_as attempt test.
  context 'A valid student attempting to login as somebody else' do
    setup do
      # Tests apply to  main controller
      @controller = MainController.new
      @admin = Admin.make
      @student = Student.make
      post_as @student, :login_as, effective_user_login: @student.user_name,
          user_login: @admin.user_name, admin_password: 'adfadsf'
    end

    should respond_with 404

    should 'render a 404 page and not touch the session' do
      assert_equal @student.id, session[:uid]
      assert_nil session[:real_uid]
    end
  end

  # TA login_as attempt test.
  context 'A valid TA attempting to login as somebody else' do
    setup do
      # Tests apply to  main controller
      @controller = MainController.new
      @admin = Admin.make
      @ta = Ta.make
      post_as @ta, :login_as, effective_user_login: @ta.user_name,
          user_login: @admin.user_name, admin_password: 'adfadsf'
    end

    should respond_with 404

    should 'render a 404 page and not touch the session' do
      assert_equal @ta.id, session[:uid]
      assert_nil session[:real_uid]
    end
  end

  # REMOTE_USER role switch tests. Note that when REMOTE_USER
  # is in place, and an admin switches roles, the
  # @markus_auth_remote_user variable will never match the
  # current user. However, it should always match session[:real_uid].
  context 'A valid admin with REMOTE_USER config on' do
    setup do
      # Make sure to mock REMOTE_USER config
      MarkusConfigurator.stubs(:markus_config_remote_user_auth).returns(true)
      # Tests apply to  main controller
      @controller = MainController.new
      @admin = Admin.make
      # Make sure to set "REMOTE_USER" via stubbing the request
      # env.
      mock_request_env = Hash.new
      mock_request_env['HTTP_X_FORWARDED_USER'] = @admin.user_name
      ActionController::TestRequest.any_instance.stubs(:env).returns(mock_request_env)
      @student = Student.make
      post :login, user_login: @admin.user_name, user_password: 'asfd'
    end

    should 'be able to log in and the session uid is correctly set' do
      assert_equal @admin.id, session[:uid]
    end

    context 'and providing empty data for effective user' do
      setup do
        post_as @admin, :login_as, effective_user_login: '',
                                   user_login: @admin.user_name
      end

      should 'NOT switch role' do
        assert_nil session[:real_uid]
      end
    end

    context 'and attempting to switch to another admin' do
      setup do
        post_as @admin, :login_as, effective_user_login: @admin.user_name,
          user_login: @admin.user_name
      end

      should 'NOT switch role' do
        assert_nil session[:real_uid]
      end
    end

    context 'when logged in' do
      setup do
        @response = post_as @admin, :login_as, effective_user_login: @student.user_name,
          user_login: @admin.user_name
      end

      should render_template '_role_switch_handler'

      should 'be able to switch to a role with lesser privileges' do
        # redirect is done by JS, so match that we get a response
        # window.location.href = <index_url>
        assert redirect_to action: 'index'
        # should have set real_uid in the session
        assert_equal @admin.id , session[:real_uid]
        assert_not_equal session[:uid], session[:real_uid]
        assert_not_nil session[:timeout]
      end

      context 'when having switched roles and logout link is NONE' do
        setup do
          # Don't really need this, but the cancel role switch link should
          # be there even if the logout link isn't.
          MarkusConfigurator.stubs(:markus_config_logout_link).returns('NONE')
          get_as @admin, :clear_role_switch_session
        end

        should redirect_to action: 'login'

        should 'be able to cancel the role switch' do
          assert_nil session[:real_uid]
          assert_nil session[:uid]
        end
      end

    end
  end

  # REMOTE_USER student login_as attempt test.
  context 'A valid student (REMOTE_USER) attempting to login as somebody else' do
    setup do
      # Make sure to mock REMOTE_USER config
      MarkusConfigurator.stubs(:markus_config_remote_user_auth).returns(true)
      # Tests apply to  main controller
      @controller = MainController.new
      @admin = Admin.make
      @student = Student.make
      # Make sure to set "REMOTE_USER" via stubbing the request
      # env.
      mock_request_env = Hash.new
      mock_request_env['HTTP_X_FORWARDED_USER'] = @student.user_name
      ActionController::TestRequest.any_instance.stubs(:env).returns(mock_request_env)
      post_as @student, :login_as, effective_user_login: @student.user_name,
          user_login: @admin.user_name
    end

    should respond_with 404

    should 'render a 404 page and not touch the session' do
      assert_equal @student.id, session[:uid]
      assert_nil session[:real_uid]
    end
  end

  # REMOTE_USER TA login_as attempt test.
  context 'A valid TA (REMOTE_USER) attempting to login as somebody else' do
    setup do
      # Make sure to mock REMOTE_USER config
      MarkusConfigurator.stubs(:markus_config_remote_user_auth).returns(true)
      # Tests apply to  main controller
      @controller = MainController.new
      @admin = Admin.make
      @ta = Ta.make
      # Make sure to set "REMOTE_USER" via stubbing the request
      # env.
      mock_request_env = Hash.new
      mock_request_env['HTTP_X_FORWARDED_USER'] = @ta.user_name
      ActionController::TestRequest.any_instance.stubs(:env).returns(mock_request_env)
      post_as @ta, :login_as, effective_user_login: @ta.user_name,
          user_login: @admin.user_name
    end

    should respond_with 404

    should 'render a 404 page and not touch the session' do
      assert_equal @ta.id, session[:uid]
      assert_nil session[:real_uid]
    end
  end

end
