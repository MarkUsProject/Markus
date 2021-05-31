# Job to run autotest tests
class AutotestRunJob < AutotestJob
  def self.show_status(_status)
    I18n.t('poll_job.autotest_run_job_enqueuing')
  end

  def self.completed_message(_status)
    I18n.t('automated_tests.tests_running')
  end

  def perform(host_with_port, user_id, assignment_id, group_ids, collected: true)
    # create and enqueue test runs
    test_batch = group_ids.size > 1 ? TestBatch.create : nil # create 1 batch object if needed
    user = User.find(user_id)
    assignment = Assignment.find(assignment_id)

    group_ids.each_slice(Settings.autotest.max_batch_size) do |group_id_slice|
      run_tests(assignment, host_with_port, group_id_slice, user, collected: collected, batch: test_batch)
    end
    AutotestResultsJob.perform_later
  end
end
