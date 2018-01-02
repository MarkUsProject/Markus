class AutotestRunJob < ApplicationJob

  # This is the waiting list for automated testing on the test client. Once a test is requested, it is enqueued
  # and it is waiting for the submission files to be copied to the test location.
  queue_as MarkusConfigurator.autotest_run_queue

  # Verify that MarkUs has student files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one source file is successfully exported.
  def repo_files_available?(assignment, repo_dir)
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
      i = Rails.cache.fetch('ate_server_tests_i') { 0 }
      next_i = (i + 1) % server_tests_config.length # use a round robin strategy
      Rails.cache.write('ate_server_tests_i', next_i)
    end
    server_tests_config[i]
  end

  def perform(host_with_port, test_scripts, user_api_key, server_api_key, grouping_id, submission_id)

    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    group = grouping.group

    # create empty test results for no submission files
    repo_dir = File.join(MarkusConfigurator.autotest_client_dir, group.repo_name)
    unless repo_files_available?(assignment, repo_dir)
      submission = submission_id.nil? ? nil : Submission.find(submission_id)
      requested_by = User.find_by(api_key: user_api_key)
      grouping.create_all_test_scripts_error_result(test_scripts.map {|s| s['file_name']}, requested_by, submission,
                                                    I18n.t('automated_tests.test_result.all_tests'),
                                                    I18n.t('automated_tests.test_result.no_source_files'))
      return
    end

    submission_path = File.join(repo_dir, assignment.repository_folder)
    assignment_tests_path = File.join(MarkusConfigurator.autotest_client_dir, assignment.repository_folder)
    markus_address = Rails.application.config.action_controller.relative_url_root.nil? ?
      host_with_port :
      host_with_port + Rails.application.config.action_controller.relative_url_root
    test_server_host = MarkusConfigurator.autotest_server_host
    test_server_user = User.find_by(user_name: test_server_host)
    if test_server_user.nil?
      return
    end
    tests_config = get_concurrent_tests_config
    files_path = MarkusConfigurator.autotest_server_files_dir
    results_path = MarkusConfigurator.autotest_server_results_dir
    file_username = MarkusConfigurator.autotest_server_files_username
    test_username = tests_config[:user]
    if test_server_host == 'localhost' || file_username == test_username
      test_username = nil
    end
    server_queue = "queue:#{tests_config[:queue]}"
    resque_params = {:class => 'AutomatedTestsServer',
                     :args => [markus_address, user_api_key, server_api_key, test_username, test_scripts,
                               'files_path_placeholder', tests_config[:dir], results_path, assignment.id, group.id,
                               group.repo_name, submission_id]}

    begin
      if test_server_host == 'localhost'
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
        Net::SSH::start(test_server_host, file_username, auth_methods: ['publickey']) do |ssh|
          ssh.exec!("mkdir -m 700 -p '#{files_path}'") # create base tests dir if not already existing
          files_path = ssh.exec!("mktemp -d --tmpdir='#{files_path}'").strip # create temp subfolder
          # copy all files using passwordless scp (natively, the net-scp gem has poor performance)
          scp_command = "scp -o PasswordAuthentication=no -o ChallengeResponseAuthentication=no -rq "\
                             "'#{submission_path}'/. '#{assignment_tests_path}'/. "\
                             "#{file_username}@#{test_server_host}:'#{files_path}'"
          Open3.capture3(scp_command)
          # enqueue remotely directly with redis-cli, resque does not allow for multiple redis servers
          resque_params[:args][5] = files_path
          ssh.exec!("redis-cli rpush \"resque:#{server_queue}\" '#{JSON.generate(resque_params)}'")
        end
      end
    rescue Exception => e
      submission = submission_id.nil? ? nil : Submission.find(submission_id)
      requested_by = User.find_by(api_key: user_api_key)
      grouping.create_all_test_scripts_error_result(test_scripts.map {|s| s['file_name']}, requested_by, submission,
                                                    I18n.t('automated_tests.test_result.all_tests'),
                                                    I18n.t('automated_tests.test_result.bad_server',
                                                      {hostname: test_server_host, error: e.message}))
    end
  end

end
