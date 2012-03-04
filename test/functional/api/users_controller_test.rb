require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

class Api::UsersControllerTest < ActionController::TestCase

  # Testing UNauthenticated requests
  context "An unauthenticated request to api/users" do
    setup do
      # Set garbage HTTP header
      @request.env['HTTP_AUTHORIZATION'] = "garbage http_header"
      @request.env['HTTP_ACCEPT'] = 'text/plain'
    end

    context "/index" do
      setup do
        get "index"
      end

      should "fail to authenticate the GET request" do
        assert_response 403
      end
    end

    context "/show" do
      setup do
        get "show", :id => 1
      end

      should "fail to authenticate the GET request" do
        assert_response 403
      end
    end

    context "/create" do
      setup do
        @res_create = post("create")
      end

      should "fail to authenticate the GET request" do
        assert_response 403
      end
    end

    context "/update" do
      setup do
        put 'update', :id => 1
      end

      should "fail to authenticate the GET request" do
        assert_response 403
      end
    end

    context "/destroy" do
      setup do
        delete "destroy", :id => 1
      end

      should "fail to authenticate the GET request" do
        assert_response 403
      end
    end
  end

  # Testing authenticated requests
  context "An authenticated request to api/users" do
    setup do
      # Fixtures have manipulated the DB, clear them off.
      clear_fixtures

      # Creates admin from blueprints.
      @admin = Admin.make
      @admin.reset_api_key
      base_encoded_md5 = @admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @request.env['HTTP_ACCEPT'] = 'text/plain'
    end

    # Testing GET
    should "testing the show function with a user that exists" do
      # Create dummy user to display
      @user = Student.make
      # fire off request, after setup has been called again, reseting API key.
      get "show", :id => 1, :user_name => @user.user_name
      assert_response :success
      assert @response.body.include?(@user.user_name)
      assert @response.body.include?(@user.type)
      assert @response.body.include?(@user.first_name)
      assert @response.body.include?(@user.last_name)
    end

    # START: Checking valid response types
    context "getting a text response" do
      setup do
        @request.env['HTTP_ACCEPT'] = 'text/plain'
        get "show", :id => "garbage"
      end

      should "be successful" do
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'text/plain'
      end
    end

    context "getting a json response" do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/json'
        get "show", :id => "garbage"
      end

      should "be successful" do
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'application/json'
      end
    end

    context "getting an xml response" do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get "show", :id => "garbage"
      end

      should "be successful" do
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'application/xml'
      end
    end

    context "getting an rss response" do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/rss'
        get "show", :id => "garbage"
      end

      should "not be successful" do
        assert_not_equal @response.content_type, 'application/rss'
      end
    end
    # FINISH: Checking valid response types

    context "testing the show function with a user that does not exist" do
      setup do
        get "show", :id => 1, :user_name => "garbage fake user "
      end

      should "fail to find the user, 'garbage fake name'" do
        assert_response 404
      end
    end

    # Testing POST
    context "testing the create function with valid attributes" do
      setup do
        # Create paramters for request
        @attr = {:user_name => "ApiTestUser", :last_name => "Tester",
                 :first_name => "Api", :user_type =>"admin" }
        # fire off request
        post "create", :id => 1, :user_name => "ApiTestUser", :last_name => "Tester",
                 :first_name => "Api", :user_type =>"admin"
      end

      should "create the new user specified" do
        assert_response :success
        @new_user = User.find_by_user_name(@attr[:user_name])
        assert !@new_user.nil?
        assert_equal(@new_user.last_name, @attr[:last_name])
        assert_equal(@new_user.first_name, @attr[:first_name])
        assert_equal(@new_user.type.downcase, @attr[:user_type])
      end
    end

    context "testing the create function with an existing user_name to cause error" do
      setup do
        @user = Student.make
        @attr = {:user_name => @user.user_name, :last_name => "Tester",
                 :first_name => "Api", :user_type =>"admin" }
        @res = post("create", @attr)
      end

      should "find an existing user and cause conflict" do
        assert !User.find_by_user_name(@attr[:user_name]).nil?
        assert_response :conflict
      end
    end

    context "testing the create function with user_type set to garbage" do
      setup do
        @attr = {:user_name => "ApiTestUser", :last_name => "Tester",
                 :first_name => "Api", :user_type =>"garbage" }
        @res = post("create", @attr)
      end

      should "not be able to process user_type" do
        assert_response 422
      end
    end

    # Testing PUT
    context "testing the update function with a new first name, last name" do
      setup do
        @user = Student.make
        @new_attr = {:user_name => @user.user_name,
                     :last_name => "TesterChanged",
                     :first_name => "UpdatedApi"}
        put "update",
            :id => 1,
            :user_name => @user.user_name,
            :last_name => "TesterChanged",
            :first_name => "UpdatedApi"
      end

      should "and a new, non-existing user name" do
        @new_attr[:new_user_name] = "apitestuser2"
        put "update",
            :id => 1,
            :user_name => @user.user_name,
            :new_user_name => 'apitestuser2',
            :last_name => "TesterChanged",
            :first_name => "UpdatedApi"

        # Try to find old user_name
        assert User.find_by_user_name(@user.user_name).nil?
        # Find user by new user_name
        @updated_user2 = User.find_by_user_name(@new_attr[:new_user_name])
        assert !@updated_user2.nil?
        assert_equal(@updated_user2.last_name, @new_attr[:last_name])
        assert_equal(@updated_user2.first_name, @new_attr[:first_name])
      end

      should "update the user's first and last name only" do
        @updated_user = User.find_by_user_name(@user.user_name)
        assert !@updated_user.nil?
        assert_equal(@updated_user.last_name, @new_attr[:last_name])
        assert_equal(@updated_user.first_name, @new_attr[:first_name])
      end
    end

    context "testing the update function with a user_name that does not exist" do
      setup do
        put "update", :id => 1, :user_name => "garbage", :last_name => "garbage",
                              :first_name => "garbage"
      end

      should "not be able to find the user_name to update" do
        assert User.find_by_user_name("garbage").nil?
        assert_response 404
      end
    end

    context "testing the update function with a new_user_name that already exists" do
      setup do
        @user_to_update = Student.make
        @existing_user = Student.make
        # fire off request
        put "update", :id => 1, :user_name => @user_to_update.user_name,
                              :last_name => "garbage",
                              :first_name => "garbage",
                              :new_user_name => @existing_user.user_name
      end

      should "find the new user_name as existing and cause conflict" do
        assert_response 409
      end
    end

    context "testing the destory function is disabled" do
      setup do
        delete "destroy", :id => 1
      end

      should "pretend the function doesn't exist" do
        assert_response :missing
      end
    end
  end
end