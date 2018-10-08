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
      if File.exist?(assignment_dir) # can exist from other assignments
        # optimize if revision hasn't changed since last test run (this test run is already saved in the db)..
        prev_test_run = TestRun.where(grouping: grouping).order(created_at: :desc).second
        if !prev_test_run.nil? &&
           prev_test_run.revision_identifier == test_run.revision_identifier &&
           prev_test_run.submission_id.nil? == test_run.submission_id.nil?
          return
        end
        # ..otherwise delete grouping's previous files
        FileUtils.rm_rf(assignment_dir)
      end
    else
      # create the automated test repository
      FileUtils.mkdir_p(AutomatedTestsClientHelper::STUDENTS_DIR)
    end
    # export the repo files
    submission = test_run.submission
    group.access_repo do |repo|
      if submission.nil?
        # TODO: Review this with the assignment_dir change
        FileUtils.rm_rf(repo_dir)
        repo.export(repo_dir)
      else
        unless assignment.only_required_files.blank?
          required_files = assignment.assignment_files.map(&:filename).to_set
        end
        submission.submission_files.each do |file|
          dir = file.path.partition(File::SEPARATOR)[2] # cut the top-level assignment dir
          file_path = dir == '' ? file.filename : File.join(dir, file.filename)
          unless required_files.nil? || required_files.include?(file_path)
            # do not export non-required files, if only required files are allowed
            # (a non-required file may end up in a repo if a hook to prevent it does not exist or is not enforced)
            next
          end
          file_content = file.retrieve_file(false, repo)
          FileUtils.mkdir_p(File.join(repo_dir, file.path))
          File.open(File.join(repo_dir, file.path, file.filename), 'wb') do |f| # binary write to avoid encoding issues
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

  def enqueue_test_run(test_run, host_with_port, test_scripts, ssh = nil)
    export_group_repo(test_run)
    unless repo_files_available?(test_run)
      # create empty test results for no submission files
      error = { name: I18n.t('automated_tests.results.all_tests'),
                message: I18n.t('automated_tests.results.no_source_files') }
      test_run.create_error_for_all_test_scripts(test_scripts.keys, error)
      return
    end

    grouping = test_run.grouping
    submission = test_run.submission
    user = test_run.user
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
    server_params = { user_type: user.type, markus_address: markus_address, user_api_key: user.api_key,
                      server_api_key: server_api_key, test_scripts: test_scripts, files_path: 'files_path_placeholder',
                      assignment_id: assignment.id, group_id: group.id, submission_id: submission&.id,
                      group_repo_name: group.repo_name, batch_id: test_run.test_batch&.id, run_id: test_run.id }

    if ssh.nil?
      # tests executed locally with no authentication
      server_path = Dir.mktmpdir(nil, server_path) # create temp subfolder
      FileUtils.cp_r("#{submission_path}/.", server_path) # includes hidden files
      server_params[:files_path] = server_path
      output, status = Open3.capture2e("#{server_command} run '#{JSON.generate(server_params)}'")
      if status.exitstatus != 0
        raise output
      end
    else
      # tests executed locally or remotely with authentication
      server_host = MarkusConfigurator.autotest_server_host
      server_username = MarkusConfigurator.autotest_server_username
      server_path = ssh.exec!("mktemp -d --tmpdir='#{server_path}'").strip # create temp subfolder
      # copy all files using passwordless scp (natively, the net-scp gem has poor performance)
      scp_command = "scp -o PasswordAuthentication=no -o ChallengeResponseAuthentication=no -rq "\
                    "'#{submission_path}'/. #{server_username}@#{server_host}:'#{server_path}'"
      Open3.capture3(scp_command)
      server_params[:files_path] = server_path
      output = ssh.exec!("#{server_command} run '#{JSON.generate(server_params)}'")
      if output.exitstatus != 0
        raise output
      end
    end
    test_run.time_to_service_estimate = output.to_i
    test_run.save
  end

  def perform(host_with_port, user_id, test_scripts, test_runs)
    # create batch if needed
    test_batch = nil
    if test_runs.size > 1
      test_batch = TestBatch.create
    end
    # set up SSH channel if needed
    server_host = MarkusConfigurator.autotest_server_host
    server_username = MarkusConfigurator.autotest_server_username
    ssh = nil
    ssh_auth_failure = nil
    unless server_username.nil?
      begin
        ssh = Net::SSH.start(server_host, server_username, auth_methods: ['publickey'], keepalive: true,
                                                           keepalive_interval: 60)
      rescue StandardError => e
        ssh_auth_failure = e
      end
    end
    # create and enqueue test runs
    test_runs.each do |test_run|
      # if user is an instructor, then a submission exists and we use that repo revision
      # if user is a student, then we use the latest repo revision
      grouping_id = test_run[:grouping_id]
      submission_id = test_run[:submission_id]
      if submission_id.nil?
        grouping = Grouping.find(grouping_id)
        revision_identifier = grouping.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      else
        submission = Submission.find(submission_id)
        revision_identifier = submission.revision_identifier
      end
      test_run = TestRun.create(
        test_batch: test_batch,
        user_id: user_id,
        grouping_id: grouping_id,
        submission_id: submission_id,
        revision_identifier: revision_identifier
      )
      begin
        unless ssh_auth_failure.nil?
          raise ssh_auth_failure
        end
        enqueue_test_run(test_run, host_with_port, test_scripts, ssh)
      rescue StandardError => e
        error = { name: I18n.t('automated_tests.results.all_tests'),
                  message: I18n.t('automated_tests.results.bad_server', hostname: server_host, error: e.message) }
        test_run.create_error_for_all_test_scripts(test_scripts.keys, error)
      end
    end
  ensure
    ssh&.close
  end

end
