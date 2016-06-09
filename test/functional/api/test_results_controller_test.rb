require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

class Api::TestResultsControllerTest < ActionController::TestCase

  #TODO: Fix these tests
=begin
  # Testing unauthenticated requests
  context 'An unauthenticated request to test_results' do
    setup do
      # Set garbage HTTP header
      @request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      @request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    context '/index' do
      setup do
        get 'index', assignment_id: 1, group_id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/show' do
      setup do
        get 'show', assignment_id: 1, group_id: 1, id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/create' do
      setup do
        post 'create', assignment_id: 1, group_id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/update' do
      setup do
        put 'update', assignment_id: 1, group_id: 1, id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/destroy' do
      setup do
        delete 'destroy', assignment_id: 1, group_id: 1, id: 1
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end
  end

  # Testing authenticated requests
  context 'An authenticated request to test_results' do
    setup do
      # Create admin from blueprints
      admin = Admin.make
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @request.env['HTTP_ACCEPT'] = 'application/xml'

      # Default XML elements displayed
      @default_xml = %w(id filename)
    end

    # Testing application/json response
    context 'getting a json response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/json'
        get 'show', assignment_id: 'garbage', group_id: 'garbage',
          id: 'garbage'
      end

      should 'be successful' do
        assert_template 'shared/http_status'
        assert_equal @response.content_type, 'application/json'
      end
    end

    # Testing application/xml response
    context 'getting an xml response' do
      setup do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get 'show', assignment_id: 'garbage', group_id: 'garbage',
          id: 'garbage'
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
        get 'show', assignment_id: 'garbage', group_id: 'garbage',
          id: 'garbage'
      end

      should 'not be successful' do
        assert_not_equal @response.content_type, 'application/rss'
      end
    end

    # Testing GET api/assignments/id/groups/id/test_results
    context 'testing index function' do
      setup do
        @group = Group.make
        @assignment = Assignment.make
        Submission.make(grouping: Grouping.make(
            group: @group, assignment: @assignment))
        submission = Submission.get_submission_by_group_and_assignment(
          @group[:group_name], @assignment[:short_identifier])
        TestResult.make(submission: submission)
        @num_tests = submission.test_results.count
      end

      should 'list all files by default' do
        get 'index', assignment_id: @assignment.id, group_id: @group.id
        assert_select 'test-result', @num_tests
      end

      should 'list only specified number if limit is used' do
        get 'index', assignment_id: @assignment.id, group_id: @group.id,
          limit: 1
        assert_select 'test-result', 1
      end
    end

    # Testing GET api/assignments/id/groups/id/test_results/id
    context 'testing show function' do
      setup do
        @group = Group.make
        @assignment = Assignment.make
        submission = Submission.make(grouping: Grouping.make(
            group: @group, assignment: @assignment))
        @test_result = TestResult.make(submission: submission)
      end

      should "send the file contents if it's a valid file" do
        get 'show', group_id: @group.id, assignment_id: @assignment.id,
          id: @test_result.id
        assert_equal @test_result.file_content, @response.body
      end

      should "return a 404 if the file doesn't exist" do
        get 'show', group_id: @group.id, assignment_id: @assignment.id,
          id: 99999
        assert_response 404
      end

      should "return a 404 if the group doesn't exist" do
        get 'index', assignment_id: @assignment.id, group_id: 9999
        assert_response 404
      end

      should "return a 404 if the assignment doesn't exist" do
        get 'index', assignment_id: 9999, group_id: @group.id
        assert_response 404
      end
    end

    # Testing DELETE api/assignments/id/groups/id/test_results/id
    context 'testing destroy' do
      setup do
        @group = Group.make
        @assignment = Assignment.make
        submission = Submission.make(grouping: Grouping.make(
            group: @group, assignment: @assignment))
        @test_result = TestResult.make(submission: submission)
      end

      should 'delete the test result_result if a valid id is given' do
        found_before = !TestResult.find_by_id(@test_result.id).nil? ? true : false
        delete 'destroy', group_id: @group.id, assignment_id: @assignment.id,
          id: @test_result.id
        found_after = !TestResult.find_by_id(@test_result.id).nil? ? true : false
        assert_equal found_before, !found_after
      end

      should "return a 404 if the file doesn't exist" do
        delete 'destroy', group_id: @group.id, assignment_id: @assignment.id,
          id: 99999
        assert_response 404
      end

      should "return a 404 if the group doesn't exist" do
        delete 'destroy', assignment_id: @assignment.id, group_id: 9999,
          id: 1
        assert_response 404
      end

      should "return a 404 if the assignment doesn't exist" do
        delete 'destroy', assignment_id: 9999, group_id: @group.id,
          id: 1
        assert_response 404
      end
    end

    # Testing POST api/assignments/id/groups/id/test_results
    context 'testing create function' do
      setup do
        @group = Group.make
        @assignment = Assignment.make
        Submission.make(grouping: Grouping.make(
            group: @group, assignment: @assignment))
        @filename = 'testing_tests.xml'
        @file_content = 'testing test files'
        @submission = Submission.get_submission_by_group_and_assignment(
          @group[:group_name], @assignment[:short_identifier])
        @existing_filename = TestResult.make(
            submission: @submission).filename
        @num_test_results = @submission.test_results.count
      end

      should "create the file if valid and doesn't already exist" do
        post 'create', group_id: @group.id, assignment_id: @assignment.id,
          filename: @filename, file_content: @file_content
        assert_response 201
        assert_equal @num_test_results + 1, @submission.test_results.length
        created_file = @submission.test_results.find_by_filename(@filename)
        assert_equal @file_content, created_file.file_content
      end

      should 'return a 409 if a file with filname already exists' do
        post 'create', group_id: @group.id, assignment_id: @assignment.id,
          filename: @existing_filename, file_content: @file_content
        assert_response 409
      end

      should "return a 404 if the group doesn't exist" do
        post 'create', group_id: 9999, assignment_id: @assignment.id,
          filename: @filename, file_content: @file_content
        assert_response 404
      end

      should "return a 404 if the assignment doesn't exist" do
        post 'create', group_id: @group.id, assignment_id: 9999,
          filename: @filename, file_content: @file_content
        assert_response 404
      end

      should "return a 422 if filename and file_content aren't both provided" do
        post 'create', group_id: @group.id, assignment_id: 9999
        assert_response 422
      end
    end

    # Testing PUT api/assignments/id/groups/id/test_results/id
    context 'testing update function' do
      setup do
        @group = Group.make
        @assignment = Assignment.make
        submission = Submission.make(grouping: Grouping.make(
            group: @group, assignment: @assignment))
        @test_result = TestResult.make(submission: submission)
        @filename = 'testing_tests.xml'
        @file_content = 'testing test files'
        @submission = Submission.get_submission_by_group_and_assignment(
          @group[:group_name], @assignment[:short_identifier])
        @taken_filename = TestResult.make(submission: @submission).filename
        @num_test_results = @submission.test_results.count
      end

      should "update the file if it's valid" do
        put 'update', group_id: @group.id, assignment_id: @assignment.id,
          id: @test_result.id, filename: @filename, file_content: @file_content
        assert_response 200
        assert_equal @num_test_results, @submission.test_results.length
        created_file = @submission.test_results.find_by_filename(@filename)
        assert_equal @file_content, created_file.file_content
      end

      should 'fail if the filename is taken by another file' do
        current_filename = @test_result.filename
        put 'update', group_id: @group.id, assignment_id: @assignment.id,
          id: @test_result.id, filename: @taken_filename
        assert_response 409
        assert_equal @num_test_results, @submission.test_results.length
        assert_equal @test_result.filename, current_filename
      end

      should "return a 404 if the group doesn't exist" do
        put 'update', group_id: 9999, assignment_id: @assignment.id,
          id: @test_result.id, filename: @filename, file_content: @file_content
        assert_response 404
      end

      should "return a 404 if the assignment doesn't exist" do
        put 'update', group_id: @group.id, assignment_id: 9999,
          id: @test_result.id, filename: @filename, file_content: @file_content
        assert_response 404
      end
    end

  end
=end
end
