##############################################################
# This is the model for the database table test_results,
# which each instance of this model represents the test result
# of a test script. It contains all the information of a test
# run, but not all the information is shown to the student.
# (Configurable for each test script) Also, the admin decides
# whether or not and when to show the result to the student.
#
# The columns of test_support_files are:
#   submission_id:      id of the submission
#   test_script_id:     id of the corresponding test script
#   completion_status:  one of {pass, fail, error}
#   marks_earned:       number of points earned for this test
#                       run. A non-negative integer.
#   input_description:  a string describing the input. It can
#                       be empty, the input data, or just
#                       a description.
#   actual_output:      actual output from running the test
#   expected_output:    expected output from running the test  
#############################################################

class TestResult < ActiveRecord::Base
  belongs_to :submission

  validates_presence_of :submission # we require an associated submission
  validates_associated :submission # submission need to be valid
  validate :completion_status, :presence => true
  validates :assignment, :presence => true
  validates :test_script, :presence => true
  validates :marks_earned, :presence => true
  validates :input_description, :presence => true
  validates :actual_output, :presence => true
  validates :expected_output, :presence => true


  #=== Description
  # Updates the file_content attribute of an TestResult object
  #=== Returns
  # True if saving with the new content succeeds, false otherwise
  def update_file_content(new_content)
    return false if new_content.nil?
    self.file_content = new_content
    return self.save
  end
end
