require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper'))
include AutomatedTestsHelper
require 'shoulda'

class AutomatedTestsHelperTest < ActiveSupport::TestCase

  def setup
    clear_fixtures
    @assignment = Assignment.new
    @token = Token.new
    @student = Student.new
    @admin = Admin.new
    @ta = Ta.new
  end

  def teardown
  end

  context "If there is at least one available server, choose_test_server" do
    setup do
      
    end
    should "return the id of an available server (positive integer)" do
      assert choose_test_server() > 0
    end
  end
  
  context "If there is no available server, choose_test_server" do
    setup do
      
    end
    should "return 0" do
      assert choose_test_server() == 0
    end
  end
  context "launch_test" do
    setup do
      
    end
    should "return true" do
      result, status = launch_test(1, 0, 0)
      assert status, result
    end
  end
  
  context "An admin allowed to run test" do
    setup do
      @admin = Admin.make
      @current_user = @admin
    end
    should "have all the files available" do
      assert files_available?
    end
  end
  
  context "An admin allowed to run test" do
    setup do
      @student = Student.make
      @current_user = @student
    end
    should "have all the files available" do
      assert files_available?
    end
  end
  
  context "An admin with no test files" do
    setup do
      @admin = Admin.make
      @current_user = @admin
    end
    should "not be allowed to run test" do
      assert !files_available?
    end
  end
  
  context "A student with no files in the repository" do
    setup do
      @studnet = Student.make
      @current_user = @student
    end
    should "not be allowed to run test" do
      assert !files_available?
    end
  end
  
  context "An admin allowed to do test" do
    setup do
      @admin = Admin.make
      @current_user = @admin
    end
    should "be allowed to do test (current_user is admin)" do
      assert can_run_test?
    end
  end

  context "A user allowed to do test" do
    setup do
      @ta = Ta.make
      @current_user = @ta
    end
    should "be allowed to do test (current_user is TA)" do
      assert can_run_test?
    end
  end

  context "A student with sufficient tokens" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.save
      @grouping = Grouping.make(:id => '2')
      @grouping.add_member(@student)
      @current_user = @student
    end
    should "be allowed to do test (current_user is student with enough tokens)" do
      assert can_run_test?
    end
  end

  context "A student without any tokens" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.tokens = 0
      @token.save
      @grouping = Grouping.make(:id => '2')
      @grouping.add_member(@student)
      @current_user = @student
    end
    should "not be allowed to do test (current_user is student with not enough tokens)" do
      assert !can_run_test?
    end
  end

  context "A student allowed to do test but without a token object" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.tokens = nil
      @token.save
      @grouping = Grouping.make(:id => '2')
      @grouping.add_member(@student)
      @current_user = @student
    end
    should "not be allowed to do test (no tokens are found for this student)" do
      assert_raise(RuntimeError) do
        can_run_test? # raises exception
      end
    end
  end

  context "A student" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.tokens = nil
      @token.save
      @current_user = @student
    end
    should "not be allowed to run tests on a group they do not belong to" do
      assert !can_run_test?
    end
  end
end
