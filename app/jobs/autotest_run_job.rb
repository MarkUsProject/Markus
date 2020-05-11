class AutotestRunJob < ApplicationJob
  include AutomatedTestsHelper

  queue_as Rails.configuration.x.queues.autotest_run

  def self.show_status(_status)
    I18n.t('poll_job.autotest_run_job_enqueuing')
  end

  def self.completed_message(_status)
    I18n.t('automated_tests.tests_running')
  end

  def create_test_run(data, test_batch, user_id)
    submission_id = data[:submission_id]
    grouping_id = data[:grouping_id]
    obj = submission_id.nil? ? Grouping.find(grouping_id) : Submission.find(submission_id)
    obj.create_test_run!(user_id: user_id, test_batch: test_batch).id
  end

  def perform(host_with_port, user_id, assignment_id, test_runs)
    # create and enqueue test runs
    # TestRun objects can either be created outside of this job (by passing their ids), or here
    test_batch = test_runs.size > 1 ? TestBatch.create : nil # create 1 batch object if needed

    test_run_ids = test_runs.map { |data| data[:id] || create_test_run(data, test_batch, user_id) }

    server_kwargs = server_params(get_markus_address(host_with_port), assignment_id)
    server_kwargs[:request_high_priority] = test_runs.length == 1 && User.find(user_id).student?
    server_kwargs[:test_data] = test_data(test_run_ids)

    begin
      run_autotester_command('run', server_kwargs)
    rescue StandardError => e
      TestRun.where(id: test_run_ids).update_all(problems: e.message)
    end
  end
end
