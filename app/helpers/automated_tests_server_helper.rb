
module AutomatedTestsServerHelper
  # This is the waiting list for automated testing on the test server. Once a test is requested, it is enqueued
  # and it is waiting for execution. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_test_queue_name

  def perform(grouping_id, arg_list, submission_id = nil)

    unless submission_id.nil?
      submission = Submission.find(submission_id)
    end
    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    group = grouping.group

    # run tests and create result files
    test_harness_path = MarkusConfigurator.markus_ate_test_runner_script_name
    test_box_path = MarkusConfigurator.markus_ate_test_run_directory
    test_harness_name = File.basename(test_harness_path)
    stdout, stderr, status = Open3.capture3("
      cd '#{test_box_path}' &&
      ruby '#{test_harness_name}' #{arg_list}
    ")
    if status.success?
      test_results_path = File.join(MarkusConfigurator.markus_config_automated_tests_repository,
                                    'test_runs',
                                    "test_run_#{Time.now.to_i}")
      FileUtils.mkdir_p(test_results_path)
      File.write("#{test_results_path}/output.txt", stdout)
      File.write("#{test_results_path}/error.txt", stderr)
      # Test scripts must now use calls to the MarkUs API to process results.
      # process_result(stdout, call_on, assignment, grouping, submission)
    else
      m_logger = MarkusLogger.instance
      src_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository,
                          group.repo_name,
                          assignment.repository_folder)
      m_logger.log("
        Error launching test in directory #{src_dir}.\n
        stdout:\n#{stdout};\n
        stderr:\n#{stderr}
                   ", MarkusLogger::ERROR)
      # TODO: handle this error better
      raise 'error'
    end
  end

end