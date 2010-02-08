require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class TestResultTest < ActiveSupport::TestCase

  fixtures :all

  # Basic testing: create, delete, update

  context "MarkUs" do
    should "be able to create and save a TestResult instance" do
      sub = submissions(:submission_1)
      test_r = TestResult.new
      test_r.filename = "this is my filename.txt"
      test_r.file_content = "Some test content."
      assert(!test_r.valid?, "No submission associated, should be invalid!")
      test_r.submission = sub
      assert(test_r.valid?, "Submission associated, TestResult instance should be valid, now!")
      assert(test_r.save, "Since Submission and TestResult is valid, it should save!")
    end

    should "be able to delete a TestResult instance" do
      test_res = test_results(:test_result_example)
      assert(test_res.valid?, "Test result instance should be valid!")
      assert(test_res.destroy, "should be able to delete a TestResult instance")
    end

    should "be able to update a TestResult instance" do
      FILENAME = "some value with_some text.txt"
      FILE_CONTENT = "a aba asdkalfdjl adklajf dadflkaj fafjla fda\nalkdafl a\n print\t\nslfjd \n"
      test_res = test_results(:test_result_example)
      # pre-update sanity checks
      assert_equal(test_res.file_content, "some text and some ...... :-)")
      assert_equal(test_res.filename, "test.txt")
      # update some values
      test_res.filename = FILENAME
      test_res.file_content = FILE_CONTENT
      assert_equal(test_res.file_content, FILE_CONTENT, "File content should be updated")
      assert_equal(test_res.filename, FILENAME, "Filename should be updated")
      assert(test_res.save)
      # check again after saving
      assert_equal(test_res.file_content, FILE_CONTENT, "File content should be updated")
      assert_equal(test_res.filename, FILENAME, "Filename should be updated")
      sub2 = submissions(:submission_2)
      test_res.submission = sub2
      assert(test_res.save)
      assert_equal(test_res.submission, sub2, "Should be the same submission instance!")
      assert(test_res.valid?, "TestResult should be valid!")
    end
  end

  context "A TestResult object" do
    should "be able to update the file_content attribute" do
      test_result = test_results(:test_result_example)
      new_content = "this is the new content\t\n"
      assert(test_result.update_file_content(new_content), "Should have saved successfully")
      assert_equal(new_content, test_result.file_content)
      # invalid content
      assert(!test_result.update_file_content(nil))
    end
  end
end
