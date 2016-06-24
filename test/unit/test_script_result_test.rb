require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestScriptResultTest < ActiveSupport::TestCase
  should belong_to :submission
  should belong_to :test_script

  should validate_presence_of :test_script
  should validate_presence_of :marks_earned

  should validate_numericality_of :marks_earned

  # create
  context "A valid test script result" do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testscriptresult = TestScriptResult.make(submission: @sub,
                                                grouping: @sub.grouping,
                                                test_script: @script,
                                                marks_earned: 5)
    end

    should "return true when a valid test script result is created" do
      assert @testscriptresult.valid?
      assert @testscriptresult.save
    end

    should "return true when a valid test script result is created even if the marks_earned is zero" do
      @testscriptresult.marks_earned = 0
      assert @testscriptresult.valid?
      assert @testscriptresult.save
    end

  end

  # update
  context "An invalid test script result" do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testscriptresult = TestScriptResult.make(submission: @sub,
                                                grouping: @sub.grouping,
                                                test_script: @script,
                                                marks_earned: 5)
    end

    should "return false when test script is nil" do
      @testscriptresult.test_script = nil
      assert !@testscriptresult.valid?, "test script result expected to be invalid when test script is nil"
    end

    should "return false when the marks_earned is negative" do
      @testscriptresult.marks_earned = -1
      assert !@testscriptresult.valid?, "test script result expected to be invalid when the marks_earned is negative"
    end

    should "return false when the marks_earned is not an integer" do
      @testscriptresult.marks_earned = 0.5
      assert !@testscriptresult.valid?, "test script result expected to be invalid when the marks_earned is not an integer"
    end

  end

  #delete
  context "MarkUs" do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testscriptresult = TestScriptResult.make(submission: @sub,
                                                grouping: @sub.grouping,
                                                test_script: @script,
                                                marks_earned: 5)
    end

    should "be able to delete a test script result" do
      assert @testscriptresult.valid?
      assert @testscriptresult.destroy
    end

  end

end
