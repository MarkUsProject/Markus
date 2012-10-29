##############################################################
# This is the model for the database table test_scripts,
# which each instance of this model represents a test script
# file submitted by the admin. It can be written in any
# scripting language (bash script, ruby, python etc.). The
# admin uploads the test script and saves in some repository
# in MarkUs. When a user sends a test request, MarkUs executes
# all the test scripts of the assignment, in the order
# specified by seq_num. The test script can assume all the
# test support files are in the same file directory to help
# running the test.
#
# The columns of test_scripts are:
#   assignment_id:      id of the assignment
#   seq_num:            a floating point number indicates the
#                       order of the execution. The test script
#                       with the smallest seq_num executes first.
#   script_name:        name of the script
#   description:        a brief description of the script. It
#                       can be shown to the students. (optionally)
#   max_marks:          maximum point a test can get for this
#                       test. It can be any non-negative integer.
#   run_on_submission:  a boolean indicates if this script is run
#                       when student submits the assignment
#   run_on_request:     a boolean indicates if this script is run
#                       when a user sends a test request
#   uses_token:         a boolean indicates if this script requires
#                       a token to run
#   halts_testing:      a boolean indicates if this script halts
#                       the test run when error occurs
#   display_description
#   display_run_status
#   display_marks_earned
#   display_input
#   display_expected_output
#   display_actual_output
#
#   The 6 columns start with "display" have similar usages.
#   Each has a value of one of {"do_not_display",
#                               "display_after_submission",
#                               "display_after_collection"},
#   which indicates whether or not and when it is displayed
#   to the student.
##############################################################

class TestScript < ActiveRecord::Base
  belongs_to :assignment
  
  validates :seq_num, :presence => true
  validates :script_name, :presence => true
  validates :max_marks, :presence => true
  validates :run_on_submission, :presence => true
  validates :run_on_request, :presence => true
  validates :uses_token, :presence => true
  validates :halts_testing, :presence => true
  validates :display_description, :presence => true
  validates :display_run_status, :presence => true
  validates :display_input, :presence => true
  validates :display_marks_earned, :presence => true
  validates :display_expected_output, :presence => true
  validates :display_actual_output, :presence => true
  
  validates_numericality_of :max_marks, :only_integer => true, :greater_than_or_equal_to => 0
  validates_inclusion_of :display_description, :in => %w(do_not_display display_after_submission display_after_collection), :error => "%{value} is not a display option"
  validates_inclusion_of :display_run_status, :in => %w(do_not_display display_after_submission display_after_collection), :error => "%{value} is not a display option"
  validates_inclusion_of :display_input, :in => %w(do_not_display display_after_submission display_after_collection), :error => "%{value} is not a display option"
  validates_inclusion_of :display_marks_earned, :in => %w(do_not_display display_after_submission display_after_collection), :error => "%{value} is not a display option"
  validates_inclusion_of :display_expected_output, :in => %w(do_not_display display_after_submission display_after_collection), :error => "%{value} is not a display option"
  validates_inclusion_of :display_actual_output, :in => %w(do_not_display display_after_submission display_after_collection), :error => "%{value} is not a display option"
end
