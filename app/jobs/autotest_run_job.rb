class AutotestRunJob < ApplicationJob
  queue_as MarkusConfigurator.autotest_run_queue

  # Export group repository for testing. Students' submitted files
  # are stored in the group repository. They must be exported
  # before copying to the test server.
  def export_group_repo(test_run)
    grouping = test_run.grouping
    group = grouping.group
    assignment = grouping.assignment
    export_path = File.join(TestRun::STUDENTS_DIR, group.repo_name)
    assignment_path = File.join(export_path, assignment.repository_folder)
    if File.exist?(TestRun::STUDENTS_DIR)
      if File.exist?(assignment_path) # can exist from other test runs
        # optimize if revision hasn't changed since last test run (this test run is already saved in the db)..
        prev_test_run = TestRun.where(grouping: grouping).order(created_at: :desc).second
        return if prev_test_run&.revision_identifier == test_run.revision_identifier
        # ..otherwise delete grouping's previous files
        FileUtils.rm_rf(assignment_path)
      end
    else
      FileUtils.mkdir_p(TestRun::STUDENTS_DIR)
    end
    # export the repo files
    required_files = nil
    if assignment.only_required_files
      required_files = assignment.assignment_files.map { |af| File.join(assignment_path, af.filename) }.to_set
    end
    group.access_repo do |repo|
      revision = repo.get_revision(test_run.revision_identifier)
      revision.tree_at_path(assignment.repository_folder, with_attrs: false).each do |_, file|
        next if file.is_a?(Repository::RevisionDirectory)
        # do not export non-required files, if only required files are allowed
        # (a non-required file may end up in a repo if a hook to prevent it does not exist or is not enforced)
        file_path = File.join(export_path, file.path, file.name)
        next unless required_files.nil? || required_files.include?(file_path)
        FileUtils.mkdir_p(File.dirname(file_path))
        # binary write to avoid encoding issues
        File.open(file_path, 'wb') { |f| f.write(repo.download_as_string(file)) }
      end
    end
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

  def enqueue_test_run(test_run, host_with_port, test_categories, ssh = nil)
    params_file = nil
    grouping = test_run.grouping
    assignment = grouping.assignment
    group = grouping.group
    error_no_files = { name: I18n.t('automated_tests.results.all_tests'),
                       message: I18n.t('automated_tests.results.no_source_files') }
    # no commits in the submission, or no commits after starter code initialization
    if test_run.revision_identifier.nil? || test_run.revision_identifier == grouping.starter_code_revision_identifier
      test_run.create_error_for_all_test_groups(test_group_ids, error_no_files)
      return
    end
    export_group_repo(test_run)
    submission_path = File.join(TestRun::STUDENTS_DIR, group.repo_name, assignment.repository_folder)
    # no assignment directory, or no files
    if !File.exist?(submission_path) ||
         (Dir.entries(submission_path) - ['.', '..'] - Repository.get_class.internal_file_names).size <= 0
      test_run.create_error_for_all_test_groups(test_group_ids, error_no_files)
      return
    end

    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_path = MarkusConfigurator.autotest_server_dir
    server_command = MarkusConfigurator.autotest_server_command
    server_api_key = get_server_api_key
    server_params = { user_type: test_run.user.type, markus_address: markus_address, server_api_key: server_api_key,
                      test_categories: test_categories, assignment_id: assignment.id, group_id: group.id,
                      submission_id: test_run.submission_id, group_repo_name: group.repo_name,
                      batch_id: test_run.test_batch_id, run_id: test_run.id }
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
    params_file&.close! # close + unlink
  end

  def perform(host_with_port, user_id, test_runs)
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

    # calculate categories based on user type
    user = User.find(user_id)
    test_categories = []
    if user.is_a?(Student)
      test_categories << TestRun::TEST_CATEGORIES[:student]
    elsif user.is_a?(Admin)
      test_categories << TestRun::TEST_CATEGORIES[:admin]
    end

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
        enqueue_test_run(test_run, host_with_port, test_categories, ssh)
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
