##############################################################
# This is the model for the database table test_results,
# which each instance of this model represents the test result
# of a test script. It contains all the information of a test
# run, but not all the information is shown to the student.
# (Configurable for each test script) Also, the admin decides
# whether or not and when to show the result to the student.
#
# The attributes of test_support_files are:
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
  belongs_to :test_script

  validates_presence_of :submission # we require an associated submission
  validates_associated :submission # submission need to be valid
  
  validates_presence_of :test_script
  validates_presence_of :completion_status
  validates_presence_of :marks_earned
  
  validates_inclusion_of :completion_status, :in => %w(pass fail error), :message => "%{value} is not a valid status"
  validates_numericality_of :marks_earned, :only_integer => true, :greater_than_or_equal_to => 0

  validates_presence_of :input_description, :if => "input_description.nil?"
  validates_presence_of :actual_output, :if => "actual_output.nil?"
  validates_presence_of :expected_output, :if => "expected_output.nil?"

end
