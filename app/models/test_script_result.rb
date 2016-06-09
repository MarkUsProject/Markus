##############################################################
# This is the model for the database table test_script_results,
# which each instance of this model represents the test result
# of a test script. It contains information of a test
# run, but not all the information is shown to the student.
# (Configurable for each test script) Also, the admin decides
# whether or not and when to show the result to the student.
#
# The attributes of test_support_files are:
#   submission_id:      id of the submission
#   test_script_id:     id of the corresponding test script
#   marks_earned:       number of points earned for this test
#                       run. A non-negative integer. It can
#                       override the marks_earned value of
#                       each unit test of this test suite
#                       when used by the rubric.
#   created_at:         time when this model is created
#   updated_at:         time when this model is modified
#############################################################

class TestScriptResult < ActiveRecord::Base
  belongs_to :submission, required: false
  belongs_to :test_script
  belongs_to :grouping

  has_many :test_results, dependent: :destroy

  validates_presence_of :grouping   # we require an associated grouping
  validates_associated  :grouping   # grouping need to be valid

  validates_presence_of :test_script
  validates_presence_of :marks_earned
  validates_presence_of :repo_revision

  validates_numericality_of :marks_earned, only_integer: true, greater_than_or_equal_to: 0

end
