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
      @request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    # Testing GET api/users
    context 'testing index function' do
      # Create three test accounts
      setup do
        @new_user1 = Student.create(:user_name => 'ApiTestStudent1',
          :last_name => 'ApiTesters', :first_name => 'ApiTesting1')
        @new_user2 = Student.create(:user_name => "ApiTestStudent2",
          :last_name => 'ApiTesters', :first_name => 'ApiTesting2')
        @new_user3 = Student.create(:user_name => 'ApiTestStudent3',
          :last_name => 'ApiTesters3', :first_name => 'ApiTesting3')
      end

      should 'get all users in the collection if no options are used' do
        get 'index'
        assert_response :success
        assert_select "user", User.all.size
      end

      should 'get only first 2 users if a limit of 2 is provided' do
        get 'index', :limit => '2'
        assert_response :success
        assert_select 'user', 2
        assert @response.body.include?(@admin.user_name)
        assert @response.body.include?(@new_user1.user_name)
      end

      should 'get the 3 latest users if a limit of 3 and offset of 1 is used' do
        get 'index', :limit => '3', :offset => '1'
        assert_response :success
        assert_select 'user', 3
        assert !@response.body.include?(@admin.user_name)
        assert @response.body.include?(@new_user1.user_name)
        assert @response.body.include?(@new_user2.user_name)
        assert @response.body.include?(@new_user3.user_name)
      end

      should 'get only matching users if a valid filter is used' do
        get 'index', :filter => 'last_name:ApiTesters'
        assert_response :success
        assert_select 'user', 2
        assert @response.body.include?(@new_user1.user_name)
        assert @response.body.include?(@new_user2.user_name)
      end

      should 'get only matching users if multiple valid filters are used' do
        get 'index', :filter => 'last_name:ApiTesters,first_name:ApiTesting1'
        assert_response :success
        assert_select 'user', 1
        assert @response.body.include?(@new_user1.user_name)
      end

      should 'ignore invalid filters' do
        get 'index', :filter => 'type:student,badfilter:invalid'
        assert_response :success
        assert_select 'user', 3
        assert @response.body.include?(@new_user1.user_name)
        assert @response.body.include?(@new_user2.user_name)
        assert @response.body.include?(@new_user3.user_name)
      end

      should 'apply limit/offset after the filter' do
        get 'index', :filter => 'last_name:ApiTesters', :limit => '1', :offset => '1'
        assert_response :success
        assert_select 'user', 1
        assert @response.body.include?(@new_user2.user_name)
      end

      should 'display all default fields if the fields parameter is not used' do
        get 'index'
        assert_response :success
        elements = ['first-name', 'last-name', 'user-name', 'notes-count',
          'grace-credits', 'id', 'type']
        elements.each do |element|
          assert_select element, {:minimum => 1}
        end
      end

      should 'only display specified fields if the fields parameter is used' do
        get 'index', :fields => 'first_name,last_name'
        assert_response :success
        assert_select 'first-name', {:minimum => 1}
        assert_select 'last-name', {:minimum => 1}
        elements = ['user-name', 'notes-count', 'grace-credits', 'id', 'type']
        elements.each do |element|
          assert_select element, 0
        end
      end

      should 'ignore invalid fields provided in the fields parameter' do
        get 'index', :fields => 'first_name,invalid_field_name'
        assert_response :success
        assert_select 'first-name', {:minimum => 1}
        elements = ['last-name', 'user-name', 'notes-count', 'grace-credits',
         'id', 'type']
        elements.each do |element|
          assert_select element, 0
        end
      end
    end

    # Testing GET api/users/:id
    context 'testing show function' do
      setup do
        @user = Student.make
      end

      should 'return only that user and all default attributes if the id is valid' do
        get 'show', :id => @user.id.to_s
        assert_response :success
        assert @response.body.include?(@user.user_name)
        elements = ['first-name', 'last-name', 'user-name', 'notes-count',
          'grace-credits', 'id', 'type']
        elements.each do |element|
          assert_select element, 1
        end
      end

      should 'return only that user and the specified fields if provided' do
        get 'show', :id => @user.id.to_s, :fields => 'first_name,user_name'
        assert_response :success
        assert @response.body.include?(@user.user_name)
        assert_select 'user-name', 1
        assert_select 'first-name', 1
        elements = ['last-name', 'notes-count', 'grace-credits', 'id', 'type']
        elements.each do |element|
          assert_select element, 0
        end
      end

      should 'return a 404 if a user with a numeric id doesn\'t exist' do
        get 'show', :id => '9999'
        assert_response 404
      end

      should 'return a 422 if the provided id is not strictly numeric' do
        get 'show', :id => '9a'
        assert_response 422
      end
    end

    # Testing text/plain response, including the use of get_plain_text
    context 'getting a text response' do
      setup do
        @user = Student.make
        @request.env['HTTP_ACCEPT'] = 'text/plain'
      end

      should 'be successful' do
        get 'show', :id => @user.id.to_s
        assert_equal @response.content_type, 'text/plain'
      end

      should 'display default attributes for a resource if fields isn\'t used' do
        get 'show', :id => @user.id.to_s
        fields = ['ID', 'User Name', 'Type', 'First Name', 'Last Name',
                  'Grace Credits Left', 'Notes']
        fields.each do |field|
          assert @response.body.include?(field)
        end
      end

      should 'display default attributes for a collection if fields isn\'t used' do
        get 'index'
        fields = ['ID', 'User Name', 'Type', 'First Name', 'Last Name',
                  'Grace Credits Left', 'Notes']
        fields.each do |field|
          assert @response.body.include?(field)
        end
      end

      should 'display only specified fields if the fields parameter is used' do
        get 'index', :fields => 'first_name,last_name'
        assert @response.body.include?('First Name')
        assert @response.body.include?('Last Name')
        fields = ['ID', 'User Name', 'Type', 'Grace Credits Left', 'Notes']
        fields.each do |field|
          assert !@response.body.include?(field)
        end
      end
    end

    # Testing application/json response
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

    # Testing application/xml response
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

    # Testing an rss response
    context "getting an rss response" do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/rss'
        get "show", :id => "garbage"
      end

      should "not be successful" do
        assert_not_equal @response.content_type, 'application/rss'
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
