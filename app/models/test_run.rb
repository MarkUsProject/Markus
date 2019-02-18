class TestRun < ApplicationRecord
  has_many :test_group_results, dependent: :destroy
  belongs_to :test_batch, optional: true
  belongs_to :submission, optional: true
  belongs_to :grouping
  belongs_to :user

  validates :time_to_service_estimate, numericality: { greater_than_or_equal_to: 0, only_integer: true,
                                                       allow_nil: true }
  validates :time_to_service, numericality: { greater_than_or_equal_to: -1, only_integer: true, allow_nil: true }

  STATUSES = {
    complete: 'complete',
    in_progress: 'in_progress',
    cancelled: 'cancelled',
    problems: 'problems'
  }.freeze

  def status
    if test_group_results.exists?
      return STATUSES[:complete]
    end
    return STATUSES[:cancelled] if time_to_service&.negative?
    STATUSES[:in_progress]
  end

  def self.statuses(test_run_ids)
    status_hash = Hash.new
    TestRun.left_outer_joins(test_group_results: :test_results)
           .where(id: test_run_ids)
           .pluck(:id, :problems, 'test_group_results.id', :time_to_service)
           .map do |id, problems, test_group_results_id, time_to_service|
      if test_group_results_id
        status_hash[id] = STATUSES[:complete]
      elsif !problems.nil?
        status_hash[id] = STATUSES[:problems]
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

  def create_test_group_result(test_group, time: 0, extra_info: nil)
    unless test_group.respond_to?(:run_by_instructors) # the ActiveRecord object can be passed directly
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

  def create_error_for_all_test_groups(test_groups, error, extra_info: nil)
    test_groups.each do |test_group|
      test_script_result = create_test_group_result(test_group, extra_info: extra_info)
      test_script_result.test_results.create(name: error[:name], status: 'error', output: error[:message])
    end
    submission&.set_autotest_marks
  end

  def create_test_group_result_from_json(json_test_group, hooks_error_all: '')
    # create test script result
    test_group_id = json_test_group['test_group_id']
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
      else
        message = I18n.t('automated_tests.results.timeout', seconds: timeout)
      end
      new_test_group_result.test_results.create(name: I18n.t('automated_tests.results.all_tests'), status: 'error',
                                               output: message)
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
    test_groups = grouping.assignment.select_test_groups(user).to_a
    json_root = nil
    begin
      json_root = JSON.parse(test_output)
    rescue StandardError => e
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.bad_results', error: e.message) }
      extra = I18n.t('automated_tests.results.extra_raw_output', extra: test_output)
      create_error_for_all_test_groups(test_groups, error, extra_info: extra)
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
    # TODO: Create a better interface to display global errors (server)
    # check for server errors
    server_error = json_root['error']
    hooks_error_all = json_root['hooks_error'] || ''
    unless server_error.blank?
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.bad_server', hostname: MarkusConfigurator.autotest_server_host,
                                                                      error: "#{server_error}") }
      extra = I18n.t('automated_tests.results.extra_raw_output', extra: test_output)
      create_error_for_all_test_groups(test_groups, error, extra_info: extra)
      return
    end

    # process results
    new_test_group_results = {}
    json_root.fetch('test_groups', []).each do |json_test_group|
      test_group_id = json_test_group['test_group_id']
      new_test_group_result = create_test_group_result_from_json(json_test_group, hooks_error_all: hooks_error_all)
      new_test_group_results[test_group_id] = new_test_group_result
    end
    # handle missing test groups (could be added while running)
    test_groups.each do |test_group|
      next if new_test_group_results.key?(test_group.id)
      new_test_group_result = create_test_group_result(test_group)
      new_test_group_result.test_results.create(name: I18n.t('automated_tests.results.all_tests'), status: 'error',
                                                output: I18n.t('automated_tests.results.missing_test_group'))
      new_test_group_results[test_group.id] = new_test_group_result
    end
    # set the marks assigned by the test run
    submission&.set_autotest_marks
  end
end
