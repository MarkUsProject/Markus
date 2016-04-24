##############################################################
# This is the model for the database table test_results,
# which each instance of this model represents the test result
# of a unit test. It contains all the information of a unit
# test.
#
# The attributes of test_support_files are:
#   test_script_result_id:  id of the corresponding test script
#   name:                   name of the unit test
#   completion_status:      one of {pass, fail, error}
#   marks_earned:           number of points earned for this unit
#                           test. A non-negative integer.
#   input_description:      a string describing the input. It can
#                           be empty, the input data, or just
#                           a description.
#   actual_output:          actual output from running the test
#   expected_output:        expected output from running the test
#############################################################

class TestResult < ActiveRecord::Base
  belongs_to :test_script_result
  validates_presence_of :test_script_result

  validates_presence_of :name
  validates_presence_of :completion_status
  validates_presence_of :marks_earned

  validates_inclusion_of :completion_status,
                         in: %w(pass fail error),
                         message: "%{value} is not a valid status"
  validates_numericality_of :marks_earned,
                            only_integer: true,
                            greater_than_or_equal_to: 0

  # input, actual_output and expected_output could be empty in some situations
  validates_presence_of :input, if: "input.nil?"
  validates_presence_of :actual_output, if: "actual_output.nil?"
  validates_presence_of :expected_output, if: "expected_output.nil?"
end
