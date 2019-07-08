class TestGroupResult < ApplicationRecord
  has_many :test_results, dependent: :destroy
  belongs_to :test_group, optional: true
  belongs_to :test_run

  validates :marks_earned, :marks_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  ERROR_TYPE = {
    no_results: :no_results,
    timeout: :timeout,
    test_error: :test_error
  }.freeze

  def create_test_result_from_json(json_test)
    # get basic attributes
    test_name = json_test.fetch('name', I18n.t('automated_tests.results.unknown_test'))
    output = json_test.fetch('output', '')
    time = json_test['time']
    status = json_test['status']
    # User code sometimes produces null bytes that are reported back to MarkUs
    # in the output. ActiveRecord cannot store null bytes so they
    # must be converted to a non-null representation.
    output.gsub!("\u0000", "\\u0000")
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
        output = I18n.t('automated_tests.results.bad_marks_earned')
        status = 'error'
        marks_earned = 0.0
      else
        marks_earned = marks_earned.to_f
      end
      marks_total = json_test['marks_total']
      if marks_total.nil?
        output = I18n.t('automated_tests.results.bad_marks_total')
        status = 'error'
        marks_earned = 0.0
        marks_total = 0.0
      else
        marks_total = marks_total.to_f
      end
      if status.nil? || !status.in?(%w[pass partial fail error])
        output = I18n.t('automated_tests.results.bad_status', status: status)
        status = 'error'
        marks_earned = 0.0
      end
    end

    # create test result
    self.test_results.create(name: test_name, status: status, output: output, marks_earned: marks_earned,
                             marks_total: marks_total, time: time)
    if stop_processing
      raise 'Test script reported a critical failure'
    end

    [marks_earned, marks_total]
  end
end
