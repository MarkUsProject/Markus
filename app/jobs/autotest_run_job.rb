# Job to run autotest tests
class AutotestRunJob < AutotestJob
  def self.show_status(_status)
    I18n.t('poll_job.autotest_run_job_enqueuing')
  end

  def perform(host_with_port, role_id, assignment_id, group_ids, user: nil, collected: true)
    # create and enqueue test runs
    role = Role.find(role_id)
    test_batch = group_ids.size > 1 ? TestBatch.create(course: role.course) : nil # create 1 batch object if needed
    assignment = Assignment.find(assignment_id)

    group_ids.each_slice(Settings.autotest.max_batch_size) do |group_id_slice|
      run_tests(assignment, host_with_port, group_id_slice, role, collected: collected, batch: test_batch)
    end
    AutotestResultsJob.perform_later
    unless user.nil?
      TestRunsChannel.broadcast_to(user, { status: 'completed', job_class: 'AutotestRunJob' })
    end
  rescue ServiceUnavailableException => e
    status.catch_exception(e)
    status[:status] = 'service_unavailable'
    unless user.nil?
      TestRunsChannel.broadcast_to(user, { **status.to_h, job_class: 'AutotestRunJob' })
    end
  rescue StandardError => e
    status.catch_exception(e)
    unless user.nil?
      TestRunsChannel.broadcast_to(user, { **status.to_h, job_class: 'AutotestRunJob' })
    end
    raise e
  end
end
