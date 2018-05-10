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
  belongs_to :submission, required: false
  belongs_to :test_script
  belongs_to :grouping
  belongs_to :requested_by, class_name: 'User', inverse_of: :test_script_results

  has_many :test_results, dependent: :destroy

  validates_presence_of :grouping   # we require an associated grouping
  validates_associated  :grouping   # grouping need to be valid

  validates_presence_of :test_script
  validates_presence_of :marks_earned
  validates_presence_of :marks_total

  validates_numericality_of :marks_earned, greater_than_or_equal_to: 0
  validates_numericality_of :marks_total, greater_than_or_equal_to: 0
  validates_numericality_of :time, only_integer: true, greater_than_or_equal_to: 0

  def create_test_result(name, input, actual, expected, marks_earned, marks_total, status)
    self.test_results.create(
      name: name,
      input: CGI.unescapeHTML(input),
      actual_output: CGI.unescapeHTML(actual),
      expected_output: CGI.unescapeHTML(expected),
      marks_earned: marks_earned,
      marks_total: marks_total,
      completion_status: status)
  end

  def create_test_error_result(name, message)
    create_test_result(name, '', message, '', 0.0, 0.0, 'error')
  end

  def create_test_result_from_xml(xml_test)
    test_name = xml_test['name']
    if test_name.nil?
      create_test_error_result(I18n.t('automated_tests.test_result.unknown_test'),
                               I18n.t('automated_tests.test_result.bad_results', {xml: xml_test}))
      raise 'Malformed xml'
    end

    input = xml_test['input'].nil? ? '' : xml_test['input']
    expected = xml_test['expected'].nil? ? '' : xml_test['expected']
    actual = xml_test['actual'].nil? ? '' : xml_test['actual']
    status = xml_test['status']
    # check first if we have to stop
    if !status.nil? && status == 'error_all'
      status = 'error'
      stop_processing = true
    else
      stop_processing = false
    end
    # look for all status and marks errors (but only the last message will be shown)
    if xml_test['marks_earned'].nil?
      actual = I18n.t('automated_tests.test_result.bad_marks_earned') unless stop_processing
      status = 'error'
      marks_earned = 0.0
    else
      marks_earned = xml_test['marks_earned'].to_f
    end
    if xml_test['marks_total'].nil?
      actual = I18n.t('automated_tests.test_result.bad_marks_total') unless stop_processing
      status = 'error'
      marks_earned = 0.0
      marks_total = 0.0
    else
      marks_total = xml_test['marks_total'].to_f
    end
    if status.nil? || !status.in?(%w(pass partial fail error))
      actual = I18n.t('automated_tests.test_result.bad_status', {status: status}) unless stop_processing
      status = 'error'
      marks_earned = 0.0
    end

    create_test_result(test_name, input, actual, expected, marks_earned, marks_total, status)
    if stop_processing
      raise 'Test script reported a serious failure'
    end

    return marks_earned, marks_total
  end

end
