require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

class Api::GroupsControllerTest < ActionController::TestCase

  # Testing unauthenticated requests
  context 'An unauthenticated request to api/assignments/id/groups' do
    setup do
      # Set garbage HTTP header
      @request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      @request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    context '/index' do
      setup do
        get 'index', assignment_id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/show' do
      setup do
        get 'show', assignment_id: '1', id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/create' do
      setup do
        post 'create', assignment_id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/update' do
      setup do
        put 'update', assignment_id: '1', id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/destroy' do
      setup do
        delete 'destroy', assignment_id: '1', id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end
  end

  # Testing authenticated requests
  context 'An authenticated request to api/assignments/id/groups' do
    setup do

      # Create admin from blueprints
      @admin = Admin.make
      @admin.reset_api_key
      base_encoded_md5 = @admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @request.env['HTTP_ACCEPT'] = 'application/xml'

      # Default XML elements displayed
      @default_xml = %w(id group-name created-at updated-at first-name
                        last-name user-name membership-status
                        student-memberships)
    end

    # Testing application/json response
    context 'getting a json response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/json'
      end

      should 'be successful' do
        get 'show', assignment_id: 'garbage', id: 'garbage'
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'application/json'
      end

      should 'not use the ActiveRecord class name as the root' do
        grouping = Grouping.make
        get 'index', assignment_id: grouping.assignment.id.to_s
        assert !@response.body.include?('{"group":')
      end
    end

    # Testing application/xml response
    context 'getting an xml response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get 'show', assignment_id: 'garbage', id: 'garbage'
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
        get 'show', assignment_id: 'garbage', id: 'garbage'
      end

      should 'not be successful' do
        assert_not_equal @response.content_type, 'application/rss'
      end
    end

    # Testing GET api/assignments/:assignment_id/groups
    context 'testing index function' do
      # Create students, groupings and assignments for testing
      setup do
        @assignment1 = Assignment.make()
        @assignment2 = Assignment.make()

        @membership1 = StudentMembership.make(user: Student.make())
        @membership2 = StudentMembership.make(user: Student.make())

        @grouping1   = Grouping.make(assignment: @assignment1,
                                     student_memberships: [@membership1])
        @grouping2   = Grouping.make(assignment: @assignment1,
                                     student_memberships: [@membership2])
        @grouping3   = Grouping.make(assignment: @assignment1)
        @grouping4   = Grouping.make(assignment: @assignment2)

        @group1      = @grouping1.group
        @group2      = @grouping2.group
        @group3      = @grouping3.group
        @group4      = @grouping4.group
      end

      should 'get all groups for an assignment if no options are used' do
        get 'index', assignment_id: @assignment1.id.to_s
        assert_response :success
        assert_select 'group', 3
        assert @response.body.include?(@group1.group_name)
        assert @response.body.include?(@group2.group_name)
        assert @response.body.include?(@group3.group_name)
      end

      should 'get only first 2 groups if a limit of 2 is provided' do
        get 'index', assignment_id: @assignment1.id.to_s, limit: '2'
        assert_response :success
        assert_select 'group', 2
        assert @response.body.include?(@group1.group_name)
        assert @response.body.include?(@group2.group_name)
      end

      should 'get next 2 groups if a limit of 2 and offset of 1 is used' do
        get 'index', assignment_id: @assignment1.id.to_s, limit: '2', offset: '1'
        assert_response :success
        assert_select 'group', 2
        assert @response.body.include?(@group2.group_name)
        assert @response.body.include?(@group3.group_name)
      end

      should 'get only matching groups if a valid filter is used' do
        get 'index', assignment_id: @assignment1.id.to_s,
          filter: "group_name:#{@group1.group_name}"
        assert_response :success
        assert_select 'group', 1
        assert @response.body.include?(@group1.group_name)
      end

      should "not return matching groups that don't belong to this assignment" do
        get 'index', assignment_id: @assignment1.id.to_s,
          filter: "group_name:#{@group4.group_name}"
        assert_response :success
        assert_select 'group', 0
        assert !@response.body.include?(@group4.group_name)
      end

      should 'ignore invalid filters' do
        get 'index', assignment_id: @assignment1.id.to_s,
          filter: "group_name:#{@group1.group_name},badfilter:invalid"
        assert_response :success
        assert_response :success
        assert_select 'group', 1
        assert @response.body.include?(@group1.group_name)
      end

      should 'use case-insensitive matching with filters' do
        get 'index', assignment_id: @assignment1.id.to_s,
          filter: "group_name:#{@group1.group_name.swapcase}"
        assert_response :success
        assert_select 'group', 1
        assert @response.body.include?(@group1.group_name)
      end

      should 'display all default fields if the fields parameter is not used' do
        get 'index', assignment_id: @assignment1.id.to_s
        assert_response :success
        @default_xml.each do |element|
          assert_select element, {minimum: 1}
        end
      end

      should 'only display specified fields if the fields parameter is used' do
        get 'index', assignment_id: @assignment1.id.to_s,
          fields: 'group_name,id'
        assert_response :success
        assert_select 'group-name', {minimum: 1}
        assert_select 'id', {minimum: 1}
        elements = Array.new(@default_xml)
        elements.delete('group-name')
        elements.delete('id')
        elements.each do |element|
          assert_select element, 0
        end
      end

      should 'ignore invalid fields provided in the fields parameter' do
        get 'index', assignment_id: @assignment2.id.to_s,
          fields: 'group_name,invalid_field_name'
        assert_response :success
        assert_select 'group-name', {minimum: 1}
        elements = Array.new(@default_xml)
        elements.delete('group-name')
        elements.each do |element|
          assert_select element, 0
        end
      end
    end

    # Testing GET api/assignments/:assignment_id/groups/:id
    context 'testing show function' do
      setup do
        # Create students, groupings and assignments for testing
        @assignment1 = Assignment.make()
        @assignment2 = Assignment.make()

        @membership1 = StudentMembership.make(user: Student.make())
        @membership2 = StudentMembership.make(user: Student.make())

        @grouping1   = Grouping.make(assignment: @assignment1,
                                     student_memberships: [@membership1])
        @grouping2   = Grouping.make(assignment: @assignment2,
                                     student_memberships: [@membership2])

        @group1      = @grouping1.group
        @group2      = @grouping2.group
      end

      should 'return only that group and default attributes if valid id' do
        get 'show', assignment_id: @assignment1.id.to_s,
          id: @group1.id.to_s
        assert_response :success
        assert @response.body.include?(@group1.group_name)
        assert !@response.body.include?(@group2.group_name)
        @default_xml.each do |element|
          assert_select element, {minimum: 1}
        end
      end

      should 'return only that group and specified fields if provided' do
        get 'show', assignment_id: @assignment2.id.to_s, id: @group2.id.to_s,
          fields: 'group_name,invalid_field_name'
        assert_response :success
        assert @response.body.include?(@group2.group_name)
        assert !@response.body.include?(@group1.group_name)
        assert_select 'group-name', 1
        elements = Array.new(@default_xml)
        elements.delete('group-name')
        elements.each do |element|
          assert_select element, 0
        end
      end

      should "return a 422 if a group isn't associated with that assignment" do
        get 'show', assignment_id: @assignment2.id.to_s, id: @group1.id.to_s
        assert_response 422
      end

      should "return a 404 if an assignment with that id doesn't exist" do
        get 'show', assignment_id: '9999', id: '9a'
        assert_response 404
      end

      should "return a 404 if a group with that id doesn't exist" do
        get 'show', assignment_id: '1', id: '9999'
        assert_response 404
      end
    end

    # Make sure the other routes don't work

    context 'testing that the create function is disabled' do
      setup do
        post 'create', assignment_id: '1', group_name: 'test'
      end

      should "pretend the function doesn't exist" do
        assert_response :missing
      end
    end

    context 'testing that the update function is disabled' do
      setup do
        put 'update', assignment_id: '1', id: '1', group_name: 'test'
      end

      should "pretend the function doesn't exist" do
        assert_response :missing
      end
    end

    context 'testing that the destroy function is disabled' do
      setup do
        delete 'destroy', assignment_id: '1', id: '1'
      end

      should "pretend the function doesn't exist" do
        assert_response :missing
      end
    end

  end
end
