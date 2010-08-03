require File.join(File.dirname(__FILE__),'../../test_helper')
require 'shoulda'
require 'base64'

# Tests the test results handlers (create, destroy, update, show)
class Api::TestResultsControllerTest < ActionController::TestCase

  fixtures :all

  context "An authenticated GET request to api/test_results" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      @test_result = test_results(:test_result_controller_test1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      filename = @test_result.filename
      # fire off request
      @res = get("show", {:group_name => group_name, :assignment => a_short_identifier,
                          :filename => filename})
    end

    should assign_to :current_user
    should "send the file contents in question" do
      assert_equal(@test_result.file_content, @res.body)
    end
  end

  context "An authenticated POST request to api/test_results" do

    setup do
      @filename = "new_test_result.txt"
      @file_content = "test content\tsome more\n\rtest\n"
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      grouping = group.grouping_for_assignment(assignment.id)
      @submission = grouping.current_submission_used
      test_results = @submission.test_results # returns Array
      @test_results_count_pre_post = test_results.length
      # fire off request
      @res = post("create", {:group_name => group_name, :assignment => a_short_identifier,
                             :filename => @filename, :file_content => @file_content})
    end

    should assign_to :current_user
    should respond_with :success
    should "create a new test result and return a 200 (success) response" do
      # need to reload submission first
      @submission.reload
      test_results = @submission.test_results # returns Array
      # check if test result object has been created
      assert_equal(@test_results_count_pre_post + 1, test_results.length,
                  "Should have created one more test result object")
      new_test_result = TestResult.find_by_filename(@filename)
      assert_not_nil(new_test_result)
      assert_equal(@file_content, new_test_result.file_content)
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/200.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated DELETE request to api/test_results" do

    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      grouping = group.grouping_for_assignment(assignment.id)
      @submission = grouping.current_submission_used
      test_results = @submission.test_results # returns Array
      @test_results_count_pre_post = test_results.length
      @to_be_deleted_test_result = "example.rb"
      @res = delete("destroy", {:group_name => group_name, :assignment => a_short_identifier,
                                :filename => @to_be_deleted_test_result})
    end

    should assign_to :current_user
    should respond_with :success
    should "delete the test result in question and return a 200 (success) response" do
      # need to reload the submission object first
      @submission.reload
      test_results = @submission.test_results # returns Array
      # check if test result object has been deleted
      assert_equal(@test_results_count_pre_post - 1, test_results.length,
                  "Should have deleted test result object")
      deleted_test_result = TestResult.find_by_filename(@to_be_deleted_test_result)
      assert_nil(deleted_test_result)
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/200.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated PUT request to api/test_results" do

    setup do
      @filename = "example.rb"
      @file_content = "new content\n\n"
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      grouping = group.grouping_for_assignment(assignment.id)
      @res = put("update", {:group_name => group_name, :assignment => a_short_identifier,
                            :filename => @filename, :file_content => @file_content})
    end

    should assign_to :current_user
    should respond_with :success
    should "update the test result in question and return a 200 (success) response" do
      updated_test_result = TestResult.find_by_filename(@filename)
      assert_not_nil(updated_test_result)
      assert_equal(@file_content, updated_test_result.file_content)
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/200.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated GET request to api/test_results with incomplete parameters" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # parameters
      @res = get("show", {:filename => "some_filename"})
    end

    should assign_to :current_user
    should respond_with 422
    should "return a 422 (Unprocessable Entity) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/422.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated POST request to api/test_results with incomplete parameters" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @res = post("create", {:filename => "some_filename"})
    end

    should assign_to :current_user
    should respond_with 422
    should "return a 422 (Unprocessable Entity) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/422.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated PUT request to api/test_results with incomplete parameters" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @res = put("update", {:filename => "some_filename"})
    end

    should assign_to :current_user
    should respond_with 422
    should "return a 422 (Unprocessable Entity) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/422.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated DELETE request to api/test_results with incomplete parameters" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @res = delete("destroy", {:filename => "somefilename"})
    end

    should assign_to :current_user
    should respond_with 422
    should "return a 422 (Unprocessable Entity) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/422.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated DELETE request to api/test_results with a non-existing filename as parameter" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      @res = delete("destroy", {:group_name => group_name, :assignment => a_short_identifier,
                                :filename => "does_not_exist"})
    end

    should assign_to :current_user
    should respond_with 404
    should "return a 404 (Not Found) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/404.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated GET request to api/test_results with a non-existing filename as parameter" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      @res = get("show", {:group_name => group_name, :assignment => a_short_identifier,
                          :filename => "does_not_exist"})
    end

    should assign_to :current_user
    should respond_with 404
    should "return a 404 (Not Found) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/404.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

  context "An authenticated PUT request to api/test_results with a non-existing filename as parameter" do
    setup do
      admin = users(:api_admin)
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      # get parameters from fixtures
      group = groups(:group_test_result1)
      assignment = assignments(:assignment_test_result1)
      group_name = group.group_name
      a_short_identifier = assignment.short_identifier
      @res = put("update", {:group_name => group_name, :assignment => a_short_identifier,
                            :filename => "does_not_exist", :file_content => "irrelevant"})
    end

    should assign_to :current_user
    should respond_with 404
    should "return a 404 (Not Found) response" do
      # check if a proper response has been sent
      res_file = File.new("#{RAILS_ROOT}/public/404.xml")
      assert_equal(res_file.read, @res.body)
    end
  end

end
