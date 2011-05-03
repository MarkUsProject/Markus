require File.join(File.dirname(__FILE__), '../../test_helper')
require File.join(File.dirname(__FILE__), '/../../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '../..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

class Api::UsersControllerTest < ActionController::TestCase
  def setup
      clear_fixtures # In case there are any left over.
      # Creates admin from blueprints.
      @admin = Admin.make
      # API key does not come set as nil, it is just a string so reset it.
      @admin.reset_api_key
      base_encoded_md5 = @admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
  end

  context "An authenticated GET request to api/users" do
    setup do
      # Create dummy user to display
      @user = Student.make
      # fire off request, after setup has been called again, reseting API key.
      @res = get("show", {:user_name => @user.user_name})
    end

    context "but with authentication changed to garbage" do
      setup do
        # Replace HTTP Header with garbage
        @request.env['HTTP_AUTHORIZATION'] = "garbage_auth_http_header"

        # fire off request
        @res = get("show", {:user_name => @user.user_name})
      end

      should "fail to authenticate" do
        assert_equal("403 Forbidden", @res.status)
      end
    end

    context "but with a garbage user_name" do
      setup do
        # fire off request
        @res = get("show", {:user_name => @user.user_name + "garbage"})
      end

      should "fail to find the user" do
        assert_equal("422 Unprocessable Entity", @res.status)
      end
    end

    should "send the user details in question" do
      # change this to international
      exp_body = I18n.t('user.user_name') + ": " + @user.user_name + "\n" +
                 I18n.t('user.user_type') + ": " + @user.type + "\n" +
                 I18n.t('user.first_name') + ": " + @user.first_name + "\n" +
                 I18n.t('user.last_name') + ": " + @user.last_name + "\n"
      assert_equal("200 OK", @res.status)
      assert_equal(exp_body, @res.body)
    end
  end

  context "An authenticated POST request to api/users creating a dummy user" do
    setup do
      # Create paramters for request
      @attr = {}
      @attr['user_name'] = "ApiTestUser"
      @attr['last_name'] = "Tester"
      @attr['first_name'] = "Api"
      @attr['user_type'] = "admin"

      # fire off request
      @res = post("create", { :user_name => @attr['user_name'],
                              :last_name => @attr['last_name'],
                              :first_name => @attr['first_name'],
                              :user_type => @attr['user_type']})
    end

    context "and then recreating it to cause an error" do
      setup do
        # fire off request
        @res = post("create", {:user_name => @attr['user_name'],
                               :last_name => "garbage",
                               :first_name => "garbage",
                               :user_type => "garbage"})
      end

      should "find an existing user and cause conflict" do
        assert !User.find_by_user_name(@attr['user_name']).nil?
        assert_equal("409 Conflict", @res.status)
      end
    end

    context "and updating it using a PUT request to api/users, changing its first and last name" do
      setup do
        # Create paramters for request
        @new_attr = {}
        @new_attr['last_name'] = "Tester2"
        @new_attr['first_name'] = "UpdatedApi"

        # fire off request
        @res = put("update", {:user_name => @attr['user_name'],
                              :last_name => @new_attr['last_name'],
                              :first_name => @new_attr['first_name']})
      end

      context "as well as the user name to one that does not exist" do
        setup do
          @new_attr['new_user_name'] = "ApiTestUser2"

          # fire off request
          @res = put("update", {:user_name => @attr['user_name'],
                                :last_name => @new_attr['last_name'],
                                :first_name => @new_attr['first_name'],
                                :new_user_name => @new_attr['new_user_name']})
        end

        should "update the dummy user's user_name, first and last name" do
          assert User.find_by_user_name(@attr['user_name']).nil?

          @updated_user2 = User.find_by_user_name(@new_attr['new_user_name'])
          assert !@updated_user2.nil?
          assert_equal(@updated_user2.last_name, @new_attr['last_name'])
          assert_equal(@updated_user2.first_name, @new_attr['first_name'])
        end
      end

      should "update the dummy user's first and last name only" do
        @updated_user = User.find_by_user_name(@attr['user_name'])
        assert !@updated_user.nil?
        assert_equal(@updated_user.last_name, @new_attr['last_name'])
        assert_equal(@updated_user.first_name, @new_attr['first_name'])
      end
    end

    should "create a new dummy user" do
      @new_user = User.find_by_user_name(@attr['user_name'])
      assert !@new_user.nil?
      assert_equal(@new_user.last_name, @attr['last_name'])
      assert_equal(@new_user.first_name, @attr['first_name'])
      assert_equal(@new_user.type.downcase, @attr['user_type'])
    end
  end

  context "An authenticated POST request to api/users creating a dummy user with an incorrect user_type" do
    setup do
      # Create paramters for request
      @attr = {}
      @attr['user_name'] = "ApiTestUser"
      @attr['last_name'] = "Tester"
      @attr['first_name'] = "Api"
      @attr['user_type'] = "garbage"

      # fire off request
      @res = post("create", { :user_name => @attr['user_name'],
                              :last_name => @attr['last_name'],
                              :first_name => @attr['first_name'],
                              :user_type => @attr['user_type']})
    end

    should "not be able to process user_type" do
      assert_equal("422 Unprocessable Entity", @res.status)
    end
  end

  context "An authenticated PUT request to api/users updating a user that does not exist" do
    setup do
      # fire off request
      @res = put("update", {:user_name => "garbage",
                            :last_name => "garbage",
                            :first_name => "garbage"})
    end

    should "not be able to find the user_name to update" do
      assert User.find_by_user_name("garbage").nil?
      assert_equal("422 Unprocessable Entity", @res.status)
    end
  end

  context "An authenticated PUT request to api/users updating a user with an existing new user_name" do
    setup do
      @user = Student.make
      @new_user = Student.make
      # fire off request
      @res = put("update", {:user_name => @user.user_name,
                            :last_name => "garbage",
                            :first_name => "garbage",
                            :new_user_name => @new_user.user_name,})
    end

    should "find the new user_name as existing and cause conflict" do
      assert_equal("409 Conflict", @res.status)
    end
  end
end
