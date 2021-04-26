class TestRun < ApplicationRecord
  enum status: { in_progress: 0, complete: 1, cancelled: 2, failed: 3 }
  has_many :test_group_results, dependent: :destroy
  has_many :feedback_files, through: :test_group_results
  belongs_to :test_batch, optional: true
  belongs_to :submission, optional: true
  belongs_to :grouping
  belongs_to :user

  ASSIGNMENTS_DIR = File.join(Settings.autotest.client_dir, 'assignments').freeze
  SPECS_FILE = 'specs.json'.freeze
  FILES_DIR = 'files'.freeze

  def cancel
    self.update(status: :cancelled) if self.in_progress?
  end

  def failure(status)
    self.update(status: failed, problems: status) if self.in_progress?
  end

  def update_results!(results)
    if results['status'] == 'failed'
      failure(results['error'])
    else
      self.update!(status: :complete, problems: results['error'])
      results['test_groups'].each do

      end
    end
  end

  def self.all_test_categories
    [Admin.name.downcase, Student.name.downcase]
  end

  def create_test_group_result(test_group, time: 0, extra_info: nil)
    unless test_group.respond_to?(:display_output) # the ActiveRecord object can be passed directly
      test_group = TestGroup.find_by(assignment: grouping.assignment, id: test_group)
      # test group can be nil if it's deleted while running
    end
    test_group_results.create(
      test_group: test_group,
      marks_earned: 0.0,
      marks_total: 0.0,
      time: time,
      extra_info: extra_info
    )
  end

  def create_test_group_result_from_json(json_test_group, hooks_error_all: '')
    # create test script result
    test_group_id = json_test_group['extra_info']['test_group_id']
    time = json_test_group.fetch('time', 0)
    stderr = json_test_group['stderr']
    malformed = json_test_group['malformed']
    hooks_stderr = "#{hooks_error_all}#{json_test_group['hooks_stderr']}"
    if stderr.blank? && malformed.blank? && hooks_stderr.blank?
      extra = nil
    else
      extra = ''
      unless stderr.blank?
        extra += I18n.t('automated_tests.results.extra_stderr', extra: stderr)
      end
      unless malformed.blank?
        extra += I18n.t('automated_tests.results.extra_malformed', extra: malformed)
      end
      unless hooks_stderr.blank?
        extra += I18n.t('automated_tests.results.extra_hooks_stderr', extra: hooks_stderr)
      end
    end
    new_test_group_result = create_test_group_result(test_group_id, time: time, extra_info: extra)
    timeout = json_test_group['timeout']
    json_tests = json_test_group['tests']
    if json_tests.blank?
      if timeout.nil?
        message = I18n.t('automated_tests.results.no_tests')
        new_test_group_result.error_type = TestGroupResult::ERROR_TYPE[:no_results]
      else
        message = I18n.t('automated_tests.results.timeout', seconds: timeout)
        new_test_group_result.error_type = TestGroupResult::ERROR_TYPE[:timeout]
      end
      new_test_group_result.test_results.create(name: I18n.t('automated_tests.results.all_tests'), status: 'error',
                                               output: message)
      new_test_group_result.save
      return new_test_group_result
    end

    # process tests
    all_marks_earned = 0.0
    all_marks_total = 0.0
    json_tests.each do |json_test|
      begin
        marks_earned, marks_total = new_test_group_result.create_test_result_from_json(json_test)
      rescue StandardError
        # the tester can signal a critical failure that requires stopping and assigning zero marks
        new_test_group_result.error_type = TestGroupResult::ERROR_TYPE[:test_error]
        all_marks_earned = 0.0
        break
      end
      all_marks_earned += marks_earned
      all_marks_total += marks_total
    end
    # handle timeout
    unless timeout.nil?
      new_test_group_result.test_results.create(name: I18n.t('automated_tests.results.all_tests'), status: 'error',
                                                output: I18n.t('automated_tests.results.timeout', seconds: timeout))
      new_test_group_result.error_type = TestGroupResult::ERROR_TYPE[:timeout]
      all_marks_earned = 0.0
    end
    # save marks
    new_test_group_result.marks_earned = all_marks_earned
    new_test_group_result.marks_total = all_marks_total
    new_test_group_result.save

    new_test_group_result
  end

  def create_test_group_results_from_json(test_output)
    # check that the output is well-formed
    begin
      json_root = JSON.parse(test_output)
    rescue StandardError => e
      self.problems = I18n.t('automated_tests.results.bad_results', error: e.message) +
                      I18n.t('automated_tests.results.extra_raw_output', extra: test_output)
      save
      return
    end
    # update estimated time to service for other runs in batch
    if self.test_batch && self.time_to_service_estimate && self.time_to_service
      time_delta = self.time_to_service_estimate - self.time_to_service
      self.test_batch.adjust_time_to_service_estimate(time_delta)
    end
    # check for server errors
    server_error = json_root['error']
    hooks_error_all = json_root['hooks_error'] || ''
    unless server_error.blank?
      self.problems = I18n.t('automated_tests.results.bad_server',
                             hostname: Settings.autotest.server_host, error: server_error) +
                      I18n.t('automated_tests.results.extra_raw_output', extra: test_output)
      save
      return
    end

    # process results
    new_test_group_results = {}
    json_root.fetch('test_groups', []).each do |json_test_group|
      test_group_id = json_test_group['extra_info']['test_group_id']
      new_test_group_result = create_test_group_result_from_json(json_test_group, hooks_error_all: hooks_error_all)
      new_test_group_results[test_group_id] = new_test_group_result
    end
    # set the marks assigned by the test run
    self.submission&.set_autotest_marks
  end
end
