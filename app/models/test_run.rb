class TestRun < ApplicationRecord
  has_many :test_script_results, dependent: :destroy
  belongs_to :test_batch
  belongs_to :submission
  belongs_to :grouping, required: true
  belongs_to :user, required: true

  validates_presence_of :revision_identifier
  validates_numericality_of :queue_len, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true
  validates_numericality_of :avg_pop_interval, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true

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
      extra_info: extra_info)
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
      message = timeout.nil? ? I18n.t('automated_tests.results.no_tests') :
                               I18n.t('automated_tests.results.timeout', seconds: timeout)
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
      rescue
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
    # TODO
    # Fix all views that use the old data from test_script_results (Handle unknown_test_script in the ui + extra_info)
    # Enqueue the other two jobs when appropriate
    # Check tokens logic (especially enqueued?)
    # TODO
    # check that the output is well-formed
    test_scripts = grouping.assignment.select_test_scripts(user).to_a
    json_root = nil
    begin
      json_root = JSON.parse(test_output)
    rescue => e
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.bad_results', error: e.message) }
      extra = I18n.t('automated_tests.results.extra_raw_output_html', extra: test_output)
      create_error_for_all_test_scripts(test_scripts, error, extra_info: extra)
      return
    end
    # save statistics
    self.queue_len = json_root['queue_len']
    self.avg_pop_interval = json_root['avg_pop_interval']
    self.save
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
      if new_test_script_results[test_script.file_name].nil?
        new_test_script_result = create_test_script_result(test_script)
        new_test_script_result.create_test_result(status: 'error',
                                                  name: I18n.t('automated_tests.results.all_tests'),
                                                  actual: I18n.t('automated_tests.results.missing_test_script'))
        new_test_script_results[test_script.file_name] = new_test_script_result
      end
    end
    # set the marks assigned by the test run
    submission&.set_autotest_marks
  end
end
