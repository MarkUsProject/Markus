class AutotestRunJob < ApplicationJob
  queue_as MarkusConfigurator.autotest_run_queue

  # Export group repository for testing. Students' submitted files
  # are stored in the group repository. They must be exported
  # before copying to the test server.
  def export_group_repo(test_run)
    grouping = test_run.grouping
    group = grouping.group
    assignment = grouping.assignment
    repo_dir = File.join(AutomatedTestsClientHelper::STUDENTS_DIR, group.repo_name)
    assignment_dir = File.join(repo_dir, assignment.repository_folder)
    if File.exist?(AutomatedTestsClientHelper::STUDENTS_DIR)
      if File.exist?(assignment_dir) # can exist from other test runs
        # optimize if revision hasn't changed since last test run (this test run is already saved in the db)..
        prev_test_run = TestRun.where(grouping: grouping).order(created_at: :desc).second
        if !prev_test_run.nil? &&
           prev_test_run.revision_identifier == test_run.revision_identifier &&
           prev_test_run.submission_id.nil? == test_run.submission_id.nil?
          return
        end
        # ..otherwise delete grouping's previous files
        if test_run.submission_id.nil?
          FileUtils.rm_rf(repo_dir)
        else
          FileUtils.rm_rf(assignment_dir)
        end
      end
    else
      FileUtils.mkdir_p(AutomatedTestsClientHelper::STUDENTS_DIR)
    end
    # export the repo files
    group.access_repo do |repo|
      if test_run.submission_id.nil?
        repo.export(repo_dir)
      else
        unless assignment.only_required_files.blank?
          required_files = assignment.assignment_files.map(&:filename).to_set
        end
        test_run.submission.submission_files.each do |file|
          dir = file.path.partition(File::SEPARATOR)[2] # cut the top-level assignment dir
          file_path = dir == '' ? file.filename : File.join(dir, file.filename)
          unless required_files.nil? || required_files.include?(file_path)
            # do not export non-required files, if only required files are allowed
            # (a non-required file may end up in a repo if a hook to prevent it does not exist or is not enforced)
            next
          end
          file_content = file.retrieve_file(false, repo)
          file_dir = File.join(repo_dir, file.path)
          FileUtils.mkdir_p(file_dir)
          File.open(File.join(file_dir, file.filename), 'wb') do |f| # binary write to avoid encoding issues
            f.write(file_content)
          end
        end
      end
    end
  end

  # Verify that MarkUs has student files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one source file is successfully exported.
  def repo_files_available?(test_run)
    grouping = test_run.grouping
    submission = test_run.submission
    assignment = grouping.assignment
    group = grouping.group
    repo_dir = File.join(AutomatedTestsClientHelper::STUDENTS_DIR, group.repo_name)
    unless submission.nil?
      # no commits in the submission
      return false if submission.revision_identifier.nil?
      # no commits after starter code initialization
      return false if submission.revision_identifier == grouping.starter_code_revision_identifier
    end
    assignment_dir = File.join(repo_dir, assignment.repository_folder)
    # no assignment directory
    return false unless File.exist?(assignment_dir)
    entries = Dir.entries(assignment_dir) - ['.', '..'] - Repository.get_class.internal_file_names
    # no files
    return false if entries.size <= 0

    true
  end

  def get_server_api_key
    server_host = MarkusConfigurator.autotest_server_host
    server_user = TestServer.find_or_create_by(user_name: server_host) do |user|
      user.first_name = 'Autotest'
      user.last_name = 'Server'
      user.hidden = true
    end
    server_user.set_api_key

    server_user.api_key
  rescue ActiveRecord::RecordNotUnique
    # find_or_create_by is not atomic, there could be race conditions on creation: we just retry until it succeeds
    retry
  end

  def enqueue_test_run(test_run, host_with_port, test_group_ids, test_specs_name, hooks_script_name, ssh = nil)
    params_file = nil
    export_group_repo(test_run)
    unless repo_files_available?(test_run)
      # create empty test results for no submission files
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.no_source_files') }
      test_run.create_error_for_all_test_groups(test_group_ids, error)
      return
    end

    grouping = test_run.grouping
    assignment = grouping.assignment
    group = grouping.group
    repo_dir = File.join(AutomatedTestsClientHelper::STUDENTS_DIR, group.repo_name)
    submission_path = File.join(repo_dir, assignment.repository_folder)
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_path = MarkusConfigurator.autotest_server_dir
    server_command = MarkusConfigurator.autotest_server_command
    server_api_key = get_server_api_key
    server_params = { user_type: test_run.user.type, markus_address: markus_address, server_api_key: server_api_key,
                      test_group_ids: test_group_ids, test_specs: test_specs_name, hooks_script: hooks_script_name,
                      assignment_id: assignment.id, group_id: group.id, submission_id: test_run.submission_id,
                      group_repo_name: group.repo_name, batch_id: test_run.test_batch_id, run_id: test_run.id }
    params_file = Tempfile.new('', submission_path)
    params_file.write(JSON.generate(server_params))
    params_file.close

    if ssh.nil?
      # tests executed locally with no authentication
      server_path = Dir.mktmpdir(nil, server_path) # create temp subfolder
      FileUtils.cp_r("#{submission_path}/.", server_path) # includes hidden files
      run_command = [server_command, 'run', '-f', "#{server_path}/#{File.basename(params_file.path)}"]
      output, status = Open3.capture2e(*run_command)
      if status.exitstatus != 0
        raise output
      end
    else
      # tests executed locally or remotely with authentication
      mkdir_command = "mktemp -d --tmpdir='#{server_path}'"
      server_path = ssh.exec!(mkdir_command).strip # create temp subfolder
      # copy all files using passwordless scp (natively, the net-scp gem has poor performance)
      server_host = MarkusConfigurator.autotest_server_host
      server_username = MarkusConfigurator.autotest_server_username
      scp_command = ['scp', '-o', 'PasswordAuthentication=no', '-o', 'ChallengeResponseAuthentication=no', '-rq',
                     "#{submission_path}/.", "#{server_username}@#{server_host}:#{server_path}"]
      Open3.capture3(*scp_command)
      run_command = "#{server_command} run -f '#{server_path}/#{File.basename(params_file.path)}'"
      output = ssh.exec!(run_command)
      if output.exitstatus != 0
        raise output
      end
    end
    test_run.time_to_service_estimate = output.to_i
    test_run.save
  ensure
    params_file&.close
    params_file&.unlink
  end

  def perform(host_with_port, user_id, test_group_ids, test_specs_name, hooks_script_name, test_runs)
    ssh = nil
    ssh_auth_failure = nil
    # set up SSH channel if needed
    server_host = MarkusConfigurator.autotest_server_host
    server_username = MarkusConfigurator.autotest_server_username
    unless server_username.nil?
      begin
        ssh = Net::SSH.start(server_host, server_username, auth_methods: ['publickey'], keepalive: true,
                                                           keepalive_interval: 60)
      rescue StandardError => e
        ssh_auth_failure = e
      end
    end
    # create and enqueue test runs
    # TestRun objects can either be created outside of this job (by passing their ids), or here
    test_batch = nil
    test_runs.each do |test_run|
      begin
        if test_run[:id].nil?
          if test_runs.size > 1 && test_batch.nil? # create 1 batch object if needed
            test_batch = TestBatch.create
          end
          submission_id = test_run[:submission_id]
          grouping_id = test_run[:grouping_id]
          obj = submission_id.nil? ? Grouping.find(grouping_id) : Submission.find(submission_id)
          test_run = obj.create_test_run!(user_id: user_id, test_batch: test_batch)
        else
          test_run = TestRun.find(test_run[:id])
        end
        unless ssh_auth_failure.nil?
          raise ssh_auth_failure
        end
        enqueue_test_run(test_run, host_with_port, test_group_ids, test_specs_name, hooks_script_name, ssh)
      rescue StandardError => e
        unless test_run.nil?
          #TODO handle test run errors this way
          #TODO display problems in the table
          test_run.problems = I18n.t('automated_tests.results.bad_server', hostname: server_host, error: e.message)
          test_run.save
        end
      end
    end
  ensure
    ssh&.close
  end

end
