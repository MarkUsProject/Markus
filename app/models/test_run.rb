class TestRun < ApplicationRecord
  has_many :test_script_results, dependent: :destroy
  belongs_to :test_batch, optional: true
  belongs_to :submission, optional: true
  belongs_to :grouping
  belongs_to :user

  validates_numericality_of :time_to_service_estimate, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true
  validates_numericality_of :time_to_service, greater_than_or_equal_to: -1, only_integer: true, allow_nil: true

  STATUSES = {
    complete: 'complete',
    in_progress: 'in_progress',
    cancelled: 'cancelled',
    complete_with_errors: 'complete_with_errors'
  }.freeze

  def status
    if test_script_results.exists?
      if test_script_results.joins(:test_results).where('test_results.completion_status': 'error').count&.positive?
        return STATUSES[:complete_with_errors]
      end
      return STATUSES[:complete]
    end
    return STATUSES[:cancelled] if time_to_service&.negative?
    STATUSES[:in_progress]
  end

  def self.statuses(test_run_ids)
    status_hash = Hash.new
    TestRun.left_outer_joins(test_script_results: :test_results)
           .where(id: test_run_ids)
           .pluck(:id, 'test_script_results.id', :time_to_service, 'test_results.completion_status')
           .map do |id, test_script_results_id, time_to_service, completion_status|
      if test_script_results_id
        if completion_status == 'error' || status_hash[id] == STATUSES[:complete_with_errors]
          status_hash[id] = STATUSES[:complete_with_errors]
        else
          status_hash[id] = STATUSES[:complete]
        end
      elsif time_to_service&.negative?
        status_hash[id] = STATUSES[:cancelled]
      else
        status_hash[id] = STATUSES[:in_progress]
      end
    end
    status_hash
  end

  STATUSES.each do |key, value|
    define_method key.to_s.concat('?').to_sym do
      return status == value
    end
  end

  def run_time
    test_script_results.pluck(:time)&.sum
  end

  def create_test_script_result(test_script, time: 0, extra_info: nil)
    unless test_script.respond_to?(:file_name) # the ActiveRecord object can be passed directly
      test_script = TestScript.find_by(assignment: grouping.assignment, file_name: test_script)
      # test script can be nil if they are deleted while running
    end
    test_script_results.create(
      test_script: test_script,
      marks_earned: 0.0,
      marks_total: 0.0,
      time: time,
      extra_info: extra_info
    )
  end

  def create_error_for_all_test_scripts(test_scripts, error, extra_info: nil)
    test_scripts.each do |test_script|
      test_script_result = create_test_script_result(test_script, extra_info: extra_info)
      test_script_result.create_test_result(status: 'error', name: error[:name], actual: error[:message])
    end
    submission&.set_autotest_marks
  end

  def create_test_script_result_from_json(json_test_script)
    # create test script result
    file_name = json_test_script['file_name']
    time = json_test_script.fetch('time', 0)
    stderr = json_test_script['stderr']
    malformed = json_test_script['malformed']
    if stderr.nil? && malformed.nil?
      extra = nil
    else
      extra = ''
      unless stderr.nil?
        extra += I18n.t('automated_tests.results.extra_stderr_html', extra: stderr)
      end
      unless malformed.nil?
        extra += I18n.t('automated_tests.results.extra_malformed_html', extra: malformed)
      end
    end
    new_test_script_result = create_test_script_result(file_name, time: time, extra_info: extra)
    timeout = json_test_script['timeout']
    json_tests = json_test_script['tests']
    if json_tests.blank?
      if timeout.nil?
        message = I18n.t('automated_tests.results.no_tests')
      else
        message = I18n.t('automated_tests.results.timeout', seconds: timeout)
      end
      new_test_script_result.create_test_result(status: 'error', name: I18n.t('automated_tests.results.all_tests'),
                                                actual: message)
      return new_test_script_result
    end

    # process tests
    all_marks_earned = 0.0
    all_marks_total = 0.0
    json_tests.each do |json_test|
      begin
        marks_earned, marks_total = new_test_script_result.create_test_result_from_json(json_test)
      rescue StandardError
        # the test script can signal a critical failure that requires stopping and assigning zero marks
        all_marks_earned = 0.0
        break
      end
      all_marks_earned += marks_earned
      all_marks_total += marks_total
    end
    # handle timeout
    unless timeout.nil?
      new_test_script_result.create_test_result(status: 'error', name: I18n.t('automated_tests.results.all_tests'),
                                                actual: I18n.t('automated_tests.results.timeout', seconds: timeout))
      all_marks_earned = 0.0
    end
    # save marks
    new_test_script_result.marks_earned = all_marks_earned
    new_test_script_result.marks_total = all_marks_total
    new_test_script_result.save

    new_test_script_result
  end

  def create_test_script_results_from_json(test_output)
    # check that the output is well-formed
    test_scripts = grouping.assignment.select_test_scripts(user).to_a
    json_root = nil
    begin
      json_root = JSON.parse(test_output)
    rescue StandardError => e
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.bad_results', error: e.message) }
      extra = I18n.t('automated_tests.results.extra_raw_output_html', extra: test_output)
      create_error_for_all_test_scripts(test_scripts, error, extra_info: extra)
      return
    end
    # save statistics
    self.time_to_service = json_root['time_to_service']
    self.save
    # update estimated time to service for other runs in batch
    if test_batch && time_to_service_estimate && time_to_service
      time_delta = time_to_service_estimate - time_to_service
      test_batch.adjust_time_to_service_estimate(time_delta)
    end
    # check for server errors
    server_error = json_root['error']
    unless server_error.blank?
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.bad_server',
                                hostname: MarkusConfigurator.autotest_server_host, error: server_error) }
      extra = I18n.t('automated_tests.results.extra_raw_output_html', extra: test_output)
      create_error_for_all_test_scripts(test_scripts, error, extra_info: extra)
      return
    end

    # process results
    new_test_script_results = {}
    json_root.fetch('test_scripts', []).each do |json_test_script|
      file_name = json_test_script['file_name']
      new_test_script_result = create_test_script_result_from_json(json_test_script)
      new_test_script_results[file_name] = new_test_script_result
    end
    # handle missing test scripts (could be added while running)
    test_scripts.each do |test_script|
      next if new_test_script_results.key?(test_script.file_name)
      new_test_script_result = create_test_script_result(test_script)
      new_test_script_result.create_test_result(status: 'error', name: I18n.t('automated_tests.results.all_tests'),
                                                actual: I18n.t('automated_tests.results.missing_test_script'))
      new_test_script_results[test_script.file_name] = new_test_script_result
    end
    # set the marks assigned by the test run
    submission&.set_autotest_marks
  end
end
