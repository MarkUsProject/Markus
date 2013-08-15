##############################################################
# This is the model for the database table test_results,
# which each instance of this model represents the test result
# of a unit test. It contains all the information of a unit
# test.
#
# The attributes of test_support_files are:
#   submission_id:      id of the submission
#   test_script_id:     id of the corresponding test script
#   name:               name of the unit test
#   completion_status:  one of {pass, fail, error}
#   marks_earned:       number of points earned for this unit
#                       test. A non-negative integer.
#   input_description:  a string describing the input. It can
#                       be empty, the input data, or just
#                       a description.
#   actual_output:      actual output from running the test
#   expected_output:    expected output from running the test
#############################################################

class TestResult < ActiveRecord::Base
  belongs_to :submission
  belongs_to :test_script
  belongs_to :grouping
  belongs_to :test_script_result

  validates_presence_of :grouping # we require an associated grouping
  validates_associated :grouping  # grouping need to be valid
  
  validates_presence_of :test_script
  validates_presence_of :name
  validates_presence_of :completion_status
  validates_presence_of :marks_earned
  validates_presence_of :repo_revision
  
  validates_inclusion_of :completion_status, :in => %w(pass fail error), :message => "%{value} is not a valid status"
  validates_numericality_of :marks_earned, :only_integer => true, :greater_than_or_equal_to => 0

  validates_presence_of :input_description, :if => "input_description.nil?"
  validates_presence_of :actual_output, :if => "actual_output.nil?"
  validates_presence_of :expected_output, :if => "expected_output.nil?"

end
