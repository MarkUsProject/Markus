require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

class Api::UsersControllerTest < ActionController::TestCase

  # Testing unauthenticated requests
  context 'An unauthenticated request to api/users' do
    setup do
      # Set garbage HTTP header
      @request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      @request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    context '/index' do
      setup do
        get 'index'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/show' do
      setup do
        get 'show', id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/create' do
      setup do
        @res_create = post('create')
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/update' do
      setup do
        put 'update', id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/destroy' do
      setup do
        delete 'destroy', id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end
  end

  # Testing authenticated requests
  context 'An authenticated request to api/users' do
    setup do

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
        @new_user1 = Student.create(user_name: 'ApiTestStudent1',
          last_name: 'ApiTesters', first_name: 'ApiTesting1')
        @new_user2 = Student.create(user_name: 'ApiTestStudent2',
          last_name: 'ApiTesters', first_name: 'ApiTesting2')
        @new_user3 = Student.create(user_name: 'ApiTestStudent3',
          last_name: 'ApiTesters3', first_name: 'ApiTesting3')
      end

      should 'get all users in the collection if no options are used' do
        get 'index'
        assert_response :success
        assert_select 'user', User.all.size
      end

      should 'get only first 2 users if a limit of 2 is provided' do
        get 'index', limit: '2'
        assert_response :success
        assert_select 'user', 2
        assert @response.body.include?(@admin.user_name)
        assert @response.body.include?(@new_user1.user_name)
      end

      should 'get the 3 latest users if a limit of 3 and offset of 1 is used' do
        get 'index', limit: '3', offset: '1'
        assert_response :success
        assert_select 'user', 3
        assert !@response.body.include?(@admin.user_name)
        assert @response.body.include?(@new_user1.user_name)
        assert @response.body.include?(@new_user2.user_name)
        assert @response.body.include?(@new_user3.user_name)
      end

      should 'get only matching users if a valid filter is used' do
        get 'index', filter: 'last_name:ApiTesters'
        assert_response :success
        assert_select 'user', 2
        assert @response.body.include?(@new_user1.user_name)
        assert @response.body.include?(@new_user2.user_name)
      end

      should 'get only matching users if multiple valid filters are used' do
        get 'index', filter: 'last_name:ApiTesters,first_name:ApiTesting1'
        assert_response :success
        assert_select 'user', 1
        assert @response.body.include?(@new_user1.user_name)
      end

      should 'ignore invalid filters' do
        get 'index', filter: 'type:student,badfilter:invalid'
        assert_response :success
        assert_select 'user', 3
        assert @response.body.include?(@new_user1.user_name)
        assert @response.body.include?(@new_user2.user_name)
        assert @response.body.include?(@new_user3.user_name)
      end

      should 'use case-insensitive matching with filters' do
        get 'index', filter: 'type:ADMIN'
        assert_response :success
        assert_select 'user', 1
        assert @response.body.include?(@admin.user_name)
      end

      should 'apply limit/offset after the filter' do
        get 'index', filter: 'last_name:ApiTesters', limit: '1', offset: '1'
        assert_response :success
        assert_select 'user', 1
        assert @response.body.include?(@new_user2.user_name)
      end

      should 'display all default fields if the fields parameter is not used' do
        get 'index'
        assert_response :success
        elements = %w(first-name last-name user-name notes-count
                      grace-credits id type)
        elements.each do |element|
          assert_select element, {minimum: 1}
        end
      end

      should 'only display specified fields if the fields parameter is used' do
        get 'index', fields: 'first_name,last_name'
        assert_response :success
        assert_select 'first-name', {minimum: 1}
        assert_select 'last-name', {minimum: 1}
        elements = %w(user-name notes-count grace-credits id type)
        elements.each do |element|
          assert_select element, 0
        end
      end

      should 'ignore invalid fields provided in the fields parameter' do
        get 'index', fields: 'first_name,invalid_field_name'
        assert_response :success
        assert_select 'first-name', {minimum: 1}
        elements = %w(last-name user-name notes-count grace-credits
                      id type)
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
        get 'show', id: @user.id.to_s
        assert_response :success
        assert @response.body.include?(@user.user_name)
        elements = %w(first-name last-name user-name notes-count
                      grace-credits id type)
        elements.each do |element|
          assert_select element, 1
        end
      end

      should 'return only that user and the specified fields if provided' do
        get 'show', id: @user.id.to_s, fields: 'first_name,user_name'
        assert_response :success
        assert @response.body.include?(@user.user_name)
        assert_select 'user-name', 1
        assert_select 'first-name', 1
        elements = %w(last-name notes-count grace-credits id type)
        elements.each do |element|
          assert_select element, 0
        end
      end

      should "return a 404 if a user with a numeric id doesn't exist" do
        get 'show', id: '9999'
        assert_response 404
      end
    end

    # Testing application/json response
    context 'getting a json response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/json'
      end

      should 'be successful' do
        get 'show', id: 'garbage'
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'application/json'
      end

      should 'not use the ActiveRecord class name as the root' do
        user = Admin.make
        get 'show', id: user.id.to_s
        assert !@response.body.include?('{"admin":')
      end
    end

    # Testing application/xml response
    context 'getting an xml response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get 'show', id: 'garbage'
      end

      should 'be successful' do
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'application/xml'
      end
    end

    # Testing an invalid HTTP_ACCEPT type
    context 'getting an rss response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/rss'
        get 'show', id: 'garbage'
      end

      should 'not be successful' do
        assert_not_equal @response.content_type, 'application/rss'
      end
    end

    # Testing POST api/users
    context 'testing the create function with valid attributes' do
      setup do
        # Create parameters for request
        @attr = { user_name: 'ApiTestUser', last_name: 'Tester',
                  first_name: 'Api', type: 'admin' }
        # fire off request
        post 'create', id: 1, user_name: 'ApiTestUser', last_name: 'Tester',
                       first_name: 'Api', type: 'admin'
      end

      should 'create the specified user' do
        assert_response 201
        @new_user = User.find_by_user_name(@attr[:user_name])
        assert !@new_user.nil?
        assert_equal(@new_user.last_name, @attr[:last_name])
        assert_equal(@new_user.first_name, @attr[:first_name])
        assert_equal(@new_user.type.downcase, @attr[:type])
      end
    end

    context 'testing the create function with an existing user_name to cause error' do
      setup do
        @user = Student.make
        @attr = {user_name: @user.user_name, last_name: 'Tester',
                 first_name: 'Api', type: 'admin' }
        @res = post('create', @attr)
      end

      should 'find an existing user and cause conflict' do
        assert !User.find_by_user_name(@attr[:user_name]).nil?
        assert_response :conflict
      end
    end

    context 'testing the create function with user_type set to garbage' do
      setup do
        @attr = {user_name: 'ApiTestUser', last_name: 'Tester',
                 first_name: 'Api', user_type: 'garbage' }
        @res = post('create', @attr)
      end

      should 'not be able to process user_type' do
        assert_response 422
      end
    end

    # Testing PUT api/users/:id
    context 'testing the update function' do
      setup do
        @user = Student.make
        @second_user = Student.make
      end

      should 'update those attributes that are supplied' do
        put 'update', id: @user.id, user_name: 'ApiTester',
            last_name: 'ApiTestLast', first_name: 'ApiTestFirst'
        updated_user = User.find_by_id(@user.id)
        assert_equal(updated_user.user_name, 'ApiTester')
        assert_equal(updated_user.last_name, 'ApiTestLast')
        assert_equal(updated_user.first_name, 'ApiTestFirst')
      end

      should 'not be able to use a user_name that already exists' do
        put 'update', id: @user.id, user_name: @second_user.user_name,
            last_name: 'ApiTestLast', first_name: 'ApiTestFirst'
        assert_response 409
      end

      should 'not be able to update a user that does not exist' do
        put 'update', id: '9999', user_name: 'RandomName'
        assert User.find_by_user_name('RandomName').nil?
        assert_response 404
      end
    end

    context 'testing that the destroy function is disabled' do
      setup do
        delete 'destroy', id: 1
      end

      should "pretend the function doesn't exist" do
        assert_response :missing
      end
    end
  end
end
