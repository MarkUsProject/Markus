require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestResultTest < ActiveSupport::TestCase
  should belong_to :test_script_result

  should validate_presence_of :test_script_result
  should validate_presence_of :name
  should validate_presence_of :completion_status
  should validate_presence_of :marks_earned

  should validate_numericality_of :marks_earned

  # create
  context 'A valid test result' do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testscriptresult = TestScriptResult.make(
        submission:    @sub,
        grouping:      @sub.grouping,
      )
      @testresult = TestResult.make(
        test_script_result: @testscriptresult,
        name:               'unit test 1',
        completion_status:  'pass',
        input:              '',
        actual_output:      '   ',
        expected_output:    'This is the expected output')
    end

    should 'return true when a valid test result is created' do
      assert @testresult.valid?
      assert @testresult.save
    end

    should 'return true when a valid test result is created even if the input is empty' do
      @testresult.input = ''
      assert @testresult.valid?
      assert @testresult.save
    end

    should 'return true when a valid test result is created even if the actual_output is empty' do
      @testresult.actual_output = ''
      assert @testresult.valid?
      assert @testresult.save
    end

    should 'return true when a valid test result is created even if the expected_output is empty' do
      @testresult.expected_output = ''
      assert @testresult.valid?
      assert @testresult.save
    end

  end

  # update
  context 'An invalid test result' do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testscriptresult = TestScriptResult.make(
        submission:    @sub,
        grouping:      @sub.grouping,
      )
      @testresult = TestResult.make(
        test_script_result: @testscriptresult,
        name:               'unit test 1',
        completion_status:  'pass',
        input:              '',
        actual_output:      '   ',
        expected_output:    'This is the expected output')
    end

    should 'return false when test script result is nil' do
      @testresult.test_script_result = nil
      @testresult.save
      assert !@testresult.valid?, 'test result expected to be invalid when test script is nil'
    end

    should 'return false when the input is nil' do
      @testresult.input = nil
      assert !@testresult.valid?, 'test result expected to be invalid when the input is nil'
    end

    should 'return false when the actual_output is nil' do
      @testresult.actual_output = nil
      assert !@testresult.valid?, 'test result expected to be invalid when the actual_output is nil'
    end

    should 'return false when the expected_output is nil' do
      @testresult.expected_output = nil
      assert !@testresult.valid?, 'test result expected to be invalid when the expected_output is nil'
    end
  end

  #delete
  context 'MarkUs' do
    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testscriptresult = TestScriptResult.make(
        submission:    @sub,
        grouping:      @sub.grouping,
      )
      @testresult = TestResult.make(
        test_script_result: @testscriptresult,
        name:               'unit test 1',
        completion_status:  'pass',
        input:              '',
        actual_output:      '   ',
        expected_output:    'This is the expected output')
    end

    should 'be able to delete a test result' do
      assert @testresult.valid?
      assert @testresult.destroy
    end
  end
end
