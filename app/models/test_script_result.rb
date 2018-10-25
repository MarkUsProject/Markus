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

class TestScriptResult < ApplicationRecord
  has_many :test_results, dependent: :destroy
  belongs_to :test_script
  belongs_to :test_run

  validates_presence_of :marks_earned
  validates_presence_of :marks_total
  validates_presence_of :time
  validates_numericality_of :marks_earned, greater_than_or_equal_to: 0
  validates_numericality_of :marks_total, greater_than_or_equal_to: 0
  validates_numericality_of :time, greater_than_or_equal_to: 0, only_integer: true

  def create_test_result(name:, input: '', actual: '', expected: '', marks_earned: 0.0, marks_total: 0.0,
                         status: 'error', time: nil)
    test_results.create(
      name: name,
      input: input,
      actual_output: actual,
      expected_output: expected,
      marks_earned: marks_earned,
      marks_total: marks_total,
      completion_status: status,
      time: time
    )
  end

  def create_test_result_from_json(json_test)
    # get basic attributes
    test_name = json_test.fetch('name', I18n.t('automated_tests.results.unknown_test'))
    input = json_test.fetch('input', '')
    expected = json_test.fetch('expected', '')
    actual = json_test.fetch('actual', '')
    time = json_test['time']
    status = json_test['status']
    # check first if we have to stop
    if !status.nil? && status == 'error_all'
      stop_processing = true
      status = 'error'
      marks_earned = 0.0
      marks_total = 0.0
    else
      stop_processing = false
      # look for all status and marks errors (only the last message will be shown)
      marks_earned = json_test['marks_earned']
      if marks_earned.nil?
        actual = I18n.t('automated_tests.results.bad_marks_earned')
        status = 'error'
        marks_earned = 0.0
      else
        marks_earned = marks_earned.to_f
      end
      marks_total = json_test['marks_total']
      if marks_total.nil?
        actual = I18n.t('automated_tests.results.bad_marks_total')
        status = 'error'
        marks_earned = 0.0
        marks_total = 0.0
      else
        marks_total = marks_total.to_f
      end
      if status.nil? || !status.in?(%w(pass partial fail error))
        actual = I18n.t('automated_tests.results.bad_status', status: status)
        status = 'error'
        marks_earned = 0.0
      end
    end

    # create test result
    create_test_result(name: test_name, input: input, actual: actual, expected: expected, marks_earned: marks_earned,
                       marks_total: marks_total, status: status, time: time)
    if stop_processing
      raise 'Test script reported a critical failure'
    end

    [marks_earned, marks_total]
  end

end
