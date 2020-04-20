class AutotestRunJob < ApplicationJob
  include AutomatedTestsHelper

  queue_as Rails.configuration.x.queues.autotest_run

  def self.show_status(status)
    if status[:progress] == status[:total]
      I18n.t('poll_job.autotest_run_job_enqueuing')
    else
      I18n.t('poll_job.autotest_run_job', progress: status[:progress], total: status[:total])
    end
  end

  def self.completed_message(status)
    I18n.t('automated_tests.tests_running')
  end

  def create_test_run(data, test_batch, user_id)
    submission_id = data[:submission_id]
    grouping_id = data[:grouping_id]
    obj = submission_id.nil? ? Grouping.find(grouping_id) : Submission.find(submission_id)
    obj.create_test_run!(user_id: user_id, test_batch: test_batch).id
  end

  def enqueue_test_runs(server_params)
    server_command = Rails.configuration.x.autotest.server_command
    server_username = Rails.configuration.x.autotest.server_username
    server_host = Rails.configuration.x.autotest.server_host
    if server_username.nil?
      run_command = [server_command, 'run', '-j', JSON.generate(server_params)]
      output, status = Open3.capture2e(*run_command)
      if status.exitstatus != 0
        raise I18n.t('automated_tests.results.bad_server', hostname: server_host, error: output)
      end
    else
      Net::SSH.start(server_host,
                     server_username,
                     auth_methods: ['publickey'],
                     keepalive: true,
                     keepalive_interval: 60) do |ssh|
        scripts_command = "#{server_command} run -j '#{JSON.generate(server_params)}'"
        output = ssh.exec!(scripts_command)
        if output.exitstatus != 0
          raise output
        end
      end
    end
  end

  def perform(host_with_port, user_id, assignment, test_runs)
    # create and enqueue test runs
    # TestRun objects can either be created outside of this job (by passing their ids), or here
    test_batch = test_runs.size > 1 ? TestBatch.create : nil  # create 1 batch object if needed

    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end

    progress.total = test_runs.count
    test_data = []
    test_runs.each do |test_run|
      test_run[:id] ||= create_test_run(test_run, test_batch, user_id)
      test_run_data = TestRun.joins(:grouping, :user)
                             .where(id: test_run[:id])
                             .pluck_to_hash('groupings.group_id as group_id',
                                            'test_runs.id as run_id',
                                            'users.type as user_type')
      test_run_data.map { |h| h[:test_categories] = [h['user_type'].downcase] }
      test_data += test_run_data
      progress.increment
    end

    server_params =  { client_type: :markus,
                       client_data: { url: markus_address,
                                      assignment_id: assignment.id,
                                      api_key: get_server_api_key },
                       test_data: test_data,
                       request_high_priority: test_runs.length == 1 && User.find(user_id).student? }
    begin
      enqueue_test_runs(server_params)
    rescue StandardError => e
      test_run_ids = test_runs.map { |h| h[:id] }
      TestRun.where(id: test_run_ids ).update_all(problems: e.message)
    end
  end
end
