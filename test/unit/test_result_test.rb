require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestResultTest < ActiveSupport::TestCase
  should belongs_to :submission
  should has_one :test_script

  should validates_presence_of :submission
  should validates_associated :submission
  
  should validates_inclusion_of :completion_status, :in => %w(pass fail error), :error => "%{value} is not a valid status"
  should validates_numericality_of :marks_earned, :only_integer => true, :greater_than_or_equal_to => 0
  
  # Basic testing: create, delete, update
  
  context "A valid test result" do
    
    setup do
      @sub = Submission.make
      @testresult = TestResult.make(:completion_status => 'pass',
                                    :marks_earned      => 5,
                                    :input_description => '',
                                    :actual_output     => '   ',
                                    :expected_output   => 'This is the expected output')
      @testresult.submission = sub
    end
    
    should "return true when a valid file is created" do
      assert @testresult.valid?
    end
    
    should "return true when the marks_earned is zero" do
      @testresult.marks_earned = 0
      assert @testresult.valid?
    end

  end
  
  context "An invalid test result" do
    
    setup do
      @sub = Submission.make
      @testresult = TestResult.make(:completion_status => 'pass',
                                    :marks_earned      => 5,
                                    :input_description => '',
                                    :actual_output     => '   ',
                                    :expected_output   => 'This is the expected output')
      @testresult.submission = sub
    end
    
    should "return false when the marks_earned is negative" do
      @testresult.marks_earned = -1
      assert !@testresult.valid?, "test result expected to be invalid when the marks_earned is negative"
    end
    
    should "return false when the marks_earned is not an integer" do
      @testresult.marks_earned = 49.5
      assert !@testresult.valid?, "test result expected to be invalid when the marks_earned is not an integer"
    end
    
    should "return false when the input_description is nil" do
      @testresult.input_description = nil
      assert !@testresult.valid?, "test result expected to be invalid when the input_description is nil"
    end
    
    should "return false when the actual_output is nil" do
      @testresult.actual_output = nil
      assert !@testresult.valid?, "test result expected to be invalid when the actual_output is nil"
    end
    
    should "return false when the expected_output is nil" do
      @testresult.expected_output = nil
      assert !@testresult.valid?, "test result expected to be invalid when the expected_output is nil"
    end
    
    should "return false when there is no submission associated" do
      @testresult.submission = nil
      assert !@testresult.valid?, "test result expected to be invalid when there is no submission associated"
    end
    
  end
  
end
