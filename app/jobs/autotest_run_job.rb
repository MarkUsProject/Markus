class AutotestRunJob < ApplicationJob

  # This is the waiting list for automated testing on the test client. Once a test is requested, it is enqueued
  # and it is waiting for the submission files to be copied to the test location.
  queue_as MarkusConfigurator.autotest_run_queue

  # Export group repository for testing. Students' submitted files
  # are stored in the group repository. They must be exported
  # before copying to the test server.
  def self.export_group_repo(group, repo_dir, assignment, submission = nil)

    # Create the automated test repository
    unless File.exist?(STUDENTS_DIR)
      FileUtils.mkdir_p(STUDENTS_DIR)
    end
    # Delete student's assignment repository if it already exists
    # TODO clean up in client worker, or try to optimize if revision is the same?
    if File.exist?(repo_dir)
      FileUtils.rm_rf(repo_dir)
    end
    # Export the correct repo revision
    if submission.nil?
      group.repo.export(repo_dir)
    else
      FileUtils.mkdir(repo_dir)
      unless assignment.only_required_files.blank?
        required_files = assignment.assignment_files.map(&:filename).to_set
      end
      submission.submission_files.each do |file|
        dir = file.path.partition(File::SEPARATOR)[2] # cut the top-level assignment dir
        file_path = if dir == '' then file.filename else File.join(dir, file.filename) end
        unless required_files.nil? || required_files.include?(file_path)
          # do not export non-required files, if only required files are allowed
          # (a non-required file may end up in a repo if a hook to prevent it does not exist or is not enforced)
          next
        end
        file_content = file.retrieve_file
        FileUtils.mkdir_p(File.join(repo_dir, file.path))
        File.open(File.join(repo_dir, file.path, file.filename), 'wb') do |f| # binary write to avoid encoding issues
          f.write(file_content)
        end
      end
    end
  end

  # Verify that MarkUs has student files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one source file is successfully exported.
  def repo_files_available?(assignment, submission, repo_dir)
    # no commits in the submission
    if !submission.nil? && submission.revision_identifier.nil?
      return false
    end
    # No assignment directory or no files in repo (only current and parent directory pointers)
    assignment_dir = File.join(repo_dir, assignment.repository_folder)
    if !File.exist?(assignment_dir) || Dir.entries(assignment_dir).length <= 2
      false
    else
      true
    end
  end

  def get_concurrent_tests_config
    server_tests_config = MarkusConfigurator.autotest_server_tests
    i = 0
    if server_tests_config.length > 1 # concurrent tests for real
      i = Rails.cache.fetch('autotest_server_tests_i') { 0 }
      next_i = (i + 1) % server_tests_config.length # use a round robin strategy
      Rails.cache.write('autotest_server_tests_i', next_i)
    end
    server_tests_config[i]
  end

  def enqueue_test_run(test_run, host_with_port, test_scripts, server_api_key)

    grouping = test_run.grouping
    submission = test_run.submission
    requested_by = test_run.user
    assignment = grouping.assignment
    group = grouping.group
    repo_dir = File.join(AutomatedTestsClientHelper::STUDENTS_DIR, group.repo_name)
    export_group_repo(group, repo_dir, assignment, submission)
    unless repo_files_available?(assignment, submission, repo_dir)
      # create empty test results for no submission files
      error = { name: I18n.t('automated_tests.test_result.all_tests'),
                message: I18n.t('automated_tests.test_result.no_source_files') }
      grouping.create_all_test_scripts_error_result(test_run, test_scripts.map { |s| s['file_name'] }, [error])
      return
    end

    submission_path = File.join(repo_dir, assignment.repository_folder)
    assignment_tests_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)
    markus_address = Rails.application.config.action_controller.relative_url_root.nil? ?
                       host_with_port :
                       host_with_port + Rails.application.config.action_controller.relative_url_root
    test_server_host = MarkusConfigurator.autotest_server_host
    tests_config = get_concurrent_tests_config
    files_path = MarkusConfigurator.autotest_server_files_dir
    results_path = MarkusConfigurator.autotest_server_results_dir
    files_username = MarkusConfigurator.autotest_server_files_username
    tests_username = tests_config[:user]
    if files_username == tests_username
      tests_username = nil
    end
    server_queue = "queue:#{tests_config[:queue]}"
    resque_params = { class: 'AutomatedTestsServer',
                      args: [markus_address, requested_by.api_key, server_api_key, tests_username, test_scripts,
                             'files_path_placeholder', tests_config[:dir], results_path, assignment.id, group.id,
                             group.repo_name, submission_id] }

    begin
      if files_username.nil?
        # tests executed locally with no authentication:
        # create a temp folder, copying the student's submission and all test files
        FileUtils.mkdir_p(files_path, {mode: 0700}) # create base files dir if not already existing
        files_path = Dir.mktmpdir(nil, files_path) # create temp subfolder
        FileUtils.cp_r("#{submission_path}/.", files_path) # includes hidden files
        FileUtils.cp_r("#{assignment_tests_path}/.", files_path) # includes hidden files
        # enqueue locally using redis api
        resque_params[:args][5] = files_path
        Resque.redis.rpush(server_queue, JSON.generate(resque_params))
      else
        # tests executed locally or remotely with authentication:
        # copy the student's submission and all test files through ssh/scp in a temp folder
        Net::SSH.start(test_server_host, files_username, auth_methods: ['publickey']) do |ssh|
          ssh.exec!("mkdir -m 700 -p '#{files_path}'") # create base tests dir if not already existing
          files_path = ssh.exec!("mktemp -d --tmpdir='#{files_path}'").strip # create temp subfolder
          # copy all files using passwordless scp (natively, the net-scp gem has poor performance)
          scp_command = "scp -o PasswordAuthentication=no -o ChallengeResponseAuthentication=no -rq "\
                             "'#{submission_path}'/. '#{assignment_tests_path}'/. "\
                             "#{files_username}@#{test_server_host}:'#{files_path}'"
          Open3.capture3(scp_command)
          # enqueue remotely directly with redis-cli, resque does not allow for multiple redis servers
          resque_params[:args][5] = files_path
          ssh.exec!("redis-cli rpush \"resque:#{server_queue}\" '#{JSON.generate(resque_params)}'")
        end
      end
    rescue Exception => e
      error = { name: I18n.t('automated_tests.test_result.all_tests'),
                message: I18n.t('automated_tests.test_result.bad_server',
                                { hostname: test_server_host, error: e.message }) }
      grouping.create_all_test_scripts_error_result(test_run, test_scripts.map { |s| s['file_name'] }, [error])
    end
  end

  def perform(host_with_port, test_scripts, user_api_key, server_api_key, test_runs)

    test_batch = nil
    if test_runs.size > 1
      test_batch = TestBatch.create
    end
    user = User.find_by(api_key: user_api_key)
    test_runs.each do |test_run|
      grouping_id = test_run['grouping_id']
      submission_id = test_run['submission_id']
      grouping = Grouping.find(grouping_id)
      submission = submission_id.nil? ? nil : Submission.find(submission_id)
      if submission.nil?
        revision_identifier = grouping.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      else
        revision_identifier = submission.revision_identifier
      end
      test_run = TestRun.create(
        test_batch: test_batch,
        user: user,
        grouping: grouping,
        submission: submission,
        revision_identifier: revision_identifier)
      enqueue_test_run(test_run, host_with_port, test_scripts, server_api_key)
    end
  end

end
