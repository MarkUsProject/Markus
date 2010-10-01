require File.dirname(__FILE__) + '/../../test_helper'
include TestFrameworkHelper
require 'shoulda'

class TestFrameworkHelperTest < ActiveSupport::TestCase

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

  context "A user allowed to do test" do
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

  context "A user allowed to do test" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.save
      @grouping = Grouping.make(:id => '2')
      @current_user = @student
    end
    should "be allowed to do test (current_user is student with enough tokens)" do
      assert can_run_test?
    end
  end

  context "A user not allowed to do test" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.tokens = 0
      @token.save
      @grouping = Grouping.make(:id => '2')
      @current_user = @student
    end
    should "not be allowed to do test (current_user is student with not enough tokens)" do
      assert !can_run_test?
    end
  end

  context "A user allowed to do test" do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.tokens = nil
      @token.save
      @grouping = Grouping.make(:id => '2')
      @current_user = @student
    end
    should "not be allowed to do test (no tokens are found for this student)" do
      assert_raise(RuntimeError) do
        can_run_test? # raises exception
      end
    end
  end
end
