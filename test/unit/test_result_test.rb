require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestResultTest < ActiveSupport::TestCase
  should belong_to :submission
  should belong_to :test_script
  
  should validate_presence_of :submission
  
  should validate_presence_of :test_script
  should validate_presence_of :completion_status
  should validate_presence_of :marks_earned
  
  should validate_numericality_of :marks_earned
  
  # create
  context "A valid test result" do
    
    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testresult = TestResult.make(:submission_id     => @sub.id,
                                    :test_script_id    => @script.id,
                                    :completion_status => 'pass',
                                    :marks_earned      => 5,
                                    :input_description => '',
                                    :actual_output     => '   ',
                                    :expected_output   => 'This is the expected output')
    end
    
    should "return true when a valid file is created" do
      assert @testresult.valid?
      assert @testresult.save
    end
    
    should "return true when a valid file is created even if the marks_earned is zero" do
      @testresult.marks_earned = 0
      assert @testresult.valid?
      assert @testresult.save
    end

    should "return true when a valid file is created even if the input_description is empty" do
      @testresult.input_description = ''
      assert @testresult.valid?
      assert @testresult.save
    end

    should "return true when a valid file is created even if the actual_output is empty" do
      @testresult.actual_output = ''
      assert @testresult.valid?
      assert @testresult.save
    end

    should "return true when a valid file is created even if the expected_output is empty" do
      @testresult.expected_output = ''
      assert @testresult.valid?
      assert @testresult.save
    end

  end
  
  # update
  context "An invalid test result" do
    
    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testresult = TestResult.make(:submission_id     => @sub.id,
                                    :test_script_id    => @script.id,
                                    :completion_status => 'pass',
                                    :marks_earned      => 5,
                                    :input_description => '',
                                    :actual_output     => '   ',
                                    :expected_output   => 'This is the expected output')
    end
    
    should "return false when there is no submission associated" do
      @testresult.submission_id = nil
      assert !@testresult.valid?, "test result expected to be invalid when there is no submission associated"
    end
    
    should "return false when test script is nil" do
      @testresult.test_script_id = nil
      assert !@testresult.valid?, "test result expected to be invalid when test script is nil"
    end
    
    should "return false when the marks_earned is negative" do
      @testresult.marks_earned = -1
      assert !@testresult.valid?, "test result expected to be invalid when the marks_earned is negative"
    end
    
    should "return false when the marks_earned is not an integer" do
      @testresult.marks_earned = 0.5
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
    
  end
  
  #delete
  context "MarkUs" do
    
    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testresult = TestResult.make(:submission_id     => @sub.id,
                                    :test_script_id    => @script.id,
                                    :completion_status => 'pass',
                                    :marks_earned      => 5,
                                    :input_description => '',
                                    :actual_output     => '   ',
                                    :expected_output   => 'This is the expected output')
    end
    
    should "be able to delete a test result" do
      assert @testresult.valid?
      assert @testresult.destroy
    end
    
  end
  
end
