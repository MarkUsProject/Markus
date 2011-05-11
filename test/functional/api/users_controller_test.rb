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
    end

    context "/show" do
      setup do
        @res_show = get("show")
      end

      should "fail to authenticate the GET request" do
        assert_equal("403 Forbidden", @res_show.status)
      end
    end

    context "/create" do
      setup do
        @res_create = post("create")
      end

      should "fail to authenticate the GET request" do
        assert_equal("403 Forbidden", @res_create.status)
      end
    end

    context "/update" do
      setup do
        @res_update = put("update")
      end

      should "fail to authenticate the GET request" do
        assert_equal("403 Forbidden", @res_update.status)
      end
    end

    context "/destroy" do
      setup do
        @res_destroy = delete("destory")
      end

      should "fail to authenticate the GET request" do
        assert_equal("403 Forbidden", @res_destroy.status)
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
    end

    # Testing GET
    context "testing the show function with a user that exists" do
      setup do
        # Create dummy user to display
        @user = Student.make
        # fire off request, after setup has been called again, reseting API key.
        @res = get("show", {:user_name => @user.user_name})
      end

      should "send the user details in question" do
        assert_equal("200 OK", @res.status)
        assert(@res.body.include?(@user.user_name))
        assert(@res.body.include?(@user.type))
        assert(@res.body.include?(@user.first_name))
        assert(@res.body.include?(@user.last_name))
      end
    end

    context "testing the show function with a user that does not exist" do
      setup do
        @res = get("show", {:user_name => "garbage fake user "})
      end

      should "fail to find the user, 'garbage fake name'" do
        assert_equal("422 Unprocessable Entity", @res.status)
      end
    end

    # Testing POST
    context "testing the create function with valid attributes" do
      setup do
        # Create paramters for request
        @attr = {:user_name => "ApiTestUser", :last_name => "Tester",
                 :first_name => "Api", :user_type =>"admin" }
        # fire off request
        @res = post("create", @attr)
      end

      should "create the new user specified" do
        assert_equal("200 OK", @res.status)
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
        assert_equal("409 Conflict", @res.status)
      end
    end

    context "testing the create function with user_type set to garbage" do
      setup do
        @attr = {:user_name => "ApiTestUser", :last_name => "Tester",
                 :first_name => "Api", :user_type =>"garbage" }
        @res = post("create", @attr)
      end

      should "not be able to process user_type" do
        assert_equal("422 Unprocessable Entity", @res.status)
      end
    end

    # Testing PUT
    context "testing the update function with a new first name, last name" do
      setup do
        @user = Student.make
        @new_attr = {:user_name => @user.user_name, :last_name => "TesterChanged",
                     :first_name => "UpdatedApi"}
        @res = put("update", @new_attr)
      end

      context "and a new, non-existing user name" do
        setup do
          @new_attr[:new_user_name] = "ApiTestUser2"
          @res = put("update", @new_attr)
        end
        should "update the user's user_name, first and last name" do
          # Try to find old user_name
          assert User.find_by_user_name(@user.user_name).nil?
          # Find user by new user_name
          @updated_user2 = User.find_by_user_name(@new_attr[:new_user_name])
          assert !@updated_user2.nil?
          assert_equal(@updated_user2.last_name, @new_attr[:last_name])
          assert_equal(@updated_user2.first_name, @new_attr[:first_name])
        end
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
        @res = put("update", {:user_name => "garbage", :last_name => "garbage",
                              :first_name => "garbage"})
      end

      should "not be able to find the user_name to update" do
        assert User.find_by_user_name("garbage").nil?
        assert_equal("422 Unprocessable Entity", @res.status)
      end
    end

    context "testing the update function with a new_user_name that already exists" do
      setup do
        @user_to_update = Student.make
        @existing_user = Student.make
        # fire off request
        @res = put("update", {:user_name => @user_to_update.user_name,
                              :last_name => "garbage",
                              :first_name => "garbage",
                              :new_user_name => @existing_user.user_name,})
      end

      should "find the new user_name as existing and cause conflict" do
        assert_equal("409 Conflict", @res.status)
      end
    end

    context "testing the destory function is disabled" do
      setup do
        @res = delete("destroy")
      end

      should "pretend the function doesn't exist" do
        assert_equal("404 Not Found", @res.status)
      end
    end
  end
end
