require 'json'
# Helper methods for Testing Framework forms
module AutomatedTestsHelper
  # This is the waiting list for automated testing. Once a test is requested,
  # it is enqueued and it is waiting for execution. Resque manages this queue.
  @queue = :test_waiting_list

  def fetch_latest_tokens_for_grouping(grouping)
    if grouping.token.nil?
      grouping.create_token(remaining: nil, last_used: nil)
    end
    grouping.token.reassign_tokens
    grouping.token
  end

  def create_test_repo(assignment)
    # Create the automated test repository
    unless File.exist?(MarkusConfigurator
                           .markus_config_automated_tests_repository)
      FileUtils.mkdir(MarkusConfigurator
                          .markus_config_automated_tests_repository)
    end

    test_dir = File.join(MarkusConfigurator
                             .markus_config_automated_tests_repository,
                         assignment.short_identifier)
    unless File.exist?(test_dir)
      FileUtils.mkdir(test_dir)
    end
  end

  # Process Testing Framework form
  # - Process new and updated test files (additional validation to be done at the model level)
  def process_test_form(assignment, params, assignment_params,
                        new_script, new_support_file)
    updated_script_files = {}
    updated_support_files = {}

    testscripts = assignment_params[:test_scripts_attributes] || []
    testsupporters = assignment_params[:test_support_files_attributes] || []

    # Create/Update test scripts
    testscripts.each do |file_num, file|
      # If no new_script then form is empty and skip
      next if testscripts[file_num][:seq_num].empty? && new_script.nil?
      if testscripts[file_num][:script_name].nil?
        # Create new test script file if one with the same name does not exist
        updated_script_files[file_num] = {}
        filename = new_script.original_filename
        if TestScript.exists?(script_name: filename, assignment: assignment)
          raise I18n.t('automated_tests.duplicate_filename') + filename
        end
        updated_script_files[file_num] = file.clone
        # Override filename from form
        updated_script_files[file_num][:script_name] = filename
        updated_script_files[file_num][:seq_num] = file_num
      else
        # Edit existing test script file
        if params[('new_update_script_' + testscripts[file_num][:script_name]).to_sym].nil?
          updated_script_files[file_num] = file.clone
        else
          new_update_script = params[('new_update_script_' + testscripts[file_num][:script_name]).to_sym]
          new_script_name = new_update_script.original_filename
          old_script_name = file[:script_name]
          if TestScript.exists?(script_name: new_script_name, assignment: assignment)
            raise I18n.t('automated_tests.duplicate_filename') + new_script_name
          end
          updated_script_files[file_num] = file.clone
          updated_script_files[file_num][:script_name] = new_script_name
          updated_script_files[file_num][:seq_num] = file_num

          # Uploading new script
          assignment_tests_path = File.join(
                    MarkusConfigurator.markus_config_automated_tests_repository,
                    @assignment.repository_folder,
                    new_script_name)
          # Replace bad line endings from windows
          contents = new_update_script.read.tr("\r", '')
          File.open(assignment_tests_path, 'w') { |f| f.write contents }

          # Deleting old script
          old_script_path = File.join(
                    MarkusConfigurator.markus_config_automated_tests_repository,
                    @assignment.repository_folder,
                    old_script_name)
          if File.exist?(old_script_path)
            File.delete(old_script_path)
          end
        end
      end
      # Always make sure the criterion type is correct.
      # The :criterion_id parameter contains a list of the form
      # [criterion_id, criterion_type]
      if testscripts[file_num][:criterion_id].nil?
        updated_script_files[file_num][:criterion_type]
      else
        crit_id, crit_type = JSON.parse testscripts[file_num][:criterion_id]
        updated_script_files[file_num][:criterion_id] = crit_id
        updated_script_files[file_num][:criterion_type] = crit_type
      end
    end

    # Create/Update test support files
    # Ignore editing files for now
    testsupporters.each do |file_num, file|
      # Empty file submission, skip
      next if testsupporters[file_num][:file_name].nil? && new_support_file.nil?
      if testsupporters[file_num][:file_name].nil?
        # Create test support file if one with the same name does not exist
        updated_support_files[file_num] = {}
        filename = new_support_file.original_filename
        if TestSupportFile.exists?(file_name: filename, assignment: assignment)
          raise I18n.t('automated_tests.duplicate_filename') + filename
        end
        updated_support_files[file_num] = file.clone
        # Override filename from form
        updated_support_files[file_num][:file_name] = filename
      else
        # Edit existing test support file
        if params[('new_update_file_' + testsupporters[file_num][:file_name]).to_sym].nil?
          updated_support_files[file_num] = file.clone
        else
          new_update_file = params[('new_update_file_' + testsupporters[file_num][:file_name]).to_sym]
          new_file_name = new_update_file.original_filename
          old_file_name = file[:file_name]
          if TestSupportFile.exists?(file_name: new_file_name, assignment: assignment)
            raise I18n.t('automated_tests.duplicate_filename') + new_file_name
          end
          updated_support_files[file_num] = file.clone
          updated_support_files[file_num][:file_name] = new_file_name

          # Uploading new file
          assignment_tests_path = File.join(
                   MarkusConfigurator.markus_config_automated_tests_repository,
                   @assignment.repository_folder,
                   new_file_name)
          File.open(
              assignment_tests_path, 'w') { |f| f.write new_update_file.read }

          # Deleting old file
          old_file_path = File.join(
                    MarkusConfigurator.markus_config_automated_tests_repository,
                    @assignment.repository_folder,
                    old_file_name)
          if File.exist?(old_file_path)
            File.delete(old_file_path)
          end
        end
      end
    end

    # Update test file attributes
    assignment.test_scripts_attributes = updated_script_files
    assignment.test_support_files_attributes = updated_support_files

    assignment.enable_test = assignment_params[:enable_test]
    assignment.unlimited_tokens = assignment_params[:unlimited_tokens]
    assignment.token_start_date = assignment_params[:token_start_date]
    assignment.token_period = assignment_params[:token_period]
    num_tokens = assignment_params[:tokens_per_period]
    if num_tokens
      assignment.tokens_per_period = num_tokens
    end

    assignment
  end

  def self.request_a_test_run(grouping_id, call_on, current_user, submission_id = nil)
    @grouping = Grouping.find(grouping_id)
    assignment = @grouping.assignment
    group = @grouping.group

    @repo_dir = File.join(
        MarkusConfigurator.markus_config_automated_tests_repository,
        group.repo_name)
    export_group_repo(group, @repo_dir)

    if files_available?(assignment) &&
      (call_on == 'collection' || has_permission?(current_user, assignment))
      Resque.enqueue(AutomatedTestsHelper, grouping_id, call_on, submission_id)
    end
  end


  # Export group repository for testing. Students' submitted files
  # are stored in the group repository. They must be exported
  # before copying to the test server.
  def self.export_group_repo(group, repo_dir)
    # Create the automated test repository
    unless File.exists?(MarkusConfigurator.markus_config_automated_tests_repository)
      FileUtils.mkdir(MarkusConfigurator.markus_config_automated_tests_repository)
    end

    # Delete student's assignment repository if it already exists
    if File.exists?(repo_dir)
      FileUtils.rm_rf(repo_dir)
    end

    group.repo.export(repo_dir)
  end


  # Find the list of test scripts to run the test. Return the list of
  # test scripts in the order specified by seq_num (running order)
  def self.scripts_to_run(assignment, call_on)
    all_scripts = TestScript.where(assignment_id: assignment.id)

    # If the test run is requested at collection (by Admin or TA),
    # All of the test scripts should be run.
    if call_on == 'collection'
      list_run_scripts = all_scripts
    elsif call_on == 'submission'
      list_run_scripts = all_scripts.select(&:run_on_submission)
    elsif call_on == 'request'
      list_run_scripts = all_scripts.select(&:run_on_request)
    else
      list_run_scripts = []
    end

    list_run_scripts.sort_by(&:seq_num)
  end


  # Verify that MarkUs has some files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one test script and
  # source files are successfully exported.
  def self.files_available?(assignment)
    test_dir = File.join(
        MarkusConfigurator.markus_config_automated_tests_repository,
        assignment.short_identifier)
    src_dir = @repo_dir
    assign_dir = @repo_dir + '/' + assignment.repository_folder

    if !File.exist?(test_dir)
      # TODO: show the error to user instead of raising a runtime error
      raise I18n.t('automated_tests.test_files_unavailable')
    elsif !File.exists?(src_dir) || !File.exist?(assign_dir)
      # TODO: show the error to user instead of raising a runtime error
      raise I18n.t('automated_tests.source_files_unavailable')
    end

    # If there are no files in repo (only current and parent directory pointers)
    if Dir.entries(assign_dir).length <= 2
      raise I18n.t('automated_tests.source_files_unavailable')
    end

    if TestScript.find_by(assignment_id: assignment.id).nil?
      # TODO: show the error to user instead of raising a runtime error
      raise I18n.t('automated_tests.test_files_unavailable')
    end

    true
  end

  # Verify the user has the permission to run the tests - admin
  # and graders always have the permission, while student has to
  # belong to the group, and have at least one token.
  def self.has_permission?(user, assignment)
    if user.admin? || user.ta?
      true
    elsif user.student?
      # Make sure student belongs to this group
      unless user.accepted_groupings.include?(@grouping)
        # TODO: show the error to user instead of raising a runtime error
        raise I18n.t('automated_tests.not_belong_to_group')
      end
      # can skip checking tokens if we have unlimited
      if assignment.unlimited_tokens
        return true
      end
      t = @grouping.token
      if t.nil?
        raise I18n.t('automated_tests.missing_tokens')
      end
      if t.remaining > 0
        t.decrease_tokens
        true
      else
        # TODO: show the error to user instead of raising a runtime error
        raise I18n.t('automated_tests.missing_tokens')
      end
    end
  end

  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  def self.perform(grouping_id, call_on, submission_id = nil)
    unless submission_id.nil?
      @submission = Submission.find(submission_id)
    end
    @grouping = Grouping.find(grouping_id)
    @assignment = @grouping.assignment
    @group = @grouping.group
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)

    stderr, result, status = launch_test(@assignment, @repo_dir, call_on)

    if !status
      #for debugging any errors in launch_test
      assignment = @assignment
      repo_dir = @repo_dir
      m_logger = MarkusLogger.instance


      src_dir = File.join(repo_dir, assignment.repository_folder)

      # Get test_dir
      test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.repository_folder)

      # Get the name of the test server
      server = 'localhost'

      # Get the directory and name of the test runner script
      test_runner = MarkusConfigurator.markus_ate_test_runner_script_name

      # Get the test run directory of the files
      run_dir = MarkusConfigurator.markus_ate_test_run_directory


      m_logger.log("error with launching test, error: #{stderr} and status:
      #{status}\n src_dir: #{src_dir}\ntest_dir: #{test_dir}\nserver:
      #{server}\ntest_runner:
      #{test_runner}\nrun_dir: #{run_dir}", MarkusLogger::ERROR)

      # TODO: handle this error better
      raise 'error'
    else
      # Test scripts must now use calls to the MarkUs API to process results.
      # process_result(result, call_on, @assignment, @grouping, @submission)
    end

  end

  # Launch the test on the test server by scp files to the server
  # and run the script.
  # This function returns three values:
  # stderr
  # stdout
  # boolean indicating whether execution suceeeded
  def self.launch_test(assignment, repo_path, call_on)
    submission_path = File.join(repo_path, assignment.repository_folder)
    assignment_tests_path = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.repository_folder)

    test_harness_path = MarkusConfigurator.markus_ate_test_runner_script_name

    # Where to run the tests
    test_box_path = MarkusConfigurator.markus_ate_test_run_directory

    # Create clean folder to execute tests
    stdout, stderr, status = Open3.capture3("rm -rf #{test_box_path} && "\
      "mkdir #{test_box_path}")
    unless status.success?
      return [stderr, stdout, status]
    end

    # Securely copy student's submission, test files and test harness script to test_box_path
    stdout, stderr, status = Open3.capture3("cp -r '#{submission_path}'/* "\
      "#{test_box_path}")
    unless status.success?
      return [stderr, stdout, status]
    end

    stdout, stderr, status = Open3.capture3(
      "cp -r '#{assignment_tests_path}'/* #{test_box_path}")
    unless status.success?
      return [stderr, stdout, status]
    end

    stdout, stderr, status = Open3.capture3("cp -r #{test_harness_path} "\
      "#{test_box_path}")
    unless status.success?
      return [stderr, stdout, status]
    end

    # Find the test scripts for this test run, and parse the argument list
    list_run_scripts = scripts_to_run(assignment, call_on)
    arg_list = ''
    list_run_scripts.each do |script|
      arg_list = arg_list + "#{script.script_name.gsub(/\s/, "\\ ")} #{script.halts_testing} "
    end

    # Run script
    test_harness_name = File.basename(test_harness_path)
    stdout, stderr, status = Open3.capture3("cd #{test_box_path}; "\
      "ruby #{test_harness_name} #{arg_list}")

    if !(status.success?)
      return [stderr, stdout, false]
    else
      test_results_path = "#{AUTOMATED_TESTS_REPOSITORY}/test_runs/test_run_#{Time.now.to_i}"
      FileUtils.mkdir_p(test_results_path)
      File.write("#{test_results_path}/output.txt", stdout)
      File.write("#{test_results_path}/error.txt", stderr)
      return [stdout, stdout, true]
    end
  end

  def self.process_result(raw_result, call_on, assignment, grouping, submission = nil)
    result = Hash.from_xml(raw_result)
    repo = grouping.group.repo
    revision = repo.get_latest_revision
    revision_number = revision.revision_number
    raw_test_scripts = result['testrun']['test_script']

    # Hash.from_xml will yield a hash if only one test script
    # and an array otherwise
    if raw_test_scripts.nil?
      return
    elsif raw_test_scripts.is_a?(Array)
      test_scripts = raw_test_scripts
    else
      test_scripts = [raw_test_scripts]
    end

    submission_id = submission ? submission.id : nil

    test_scripts.each do |script|
      marks_earned = 0
      script_name = script['script_name']
      test_script = TestScript.find_by(assignment_id: assignment.id,
                                       script_name: script_name)

      new_test_script_result = grouping.test_script_results.create!(
        test_script_id: test_script.id,
        submission_id: submission_id,
        marks_earned: 0,
        repo_revision: revision_number)

      tests = script['test'] || []  # there may not be any test results
      # same workaround as above, Hash.from_xml produces a hash if it's a single test
      unless tests.is_a?(Array)
        tests = [tests]
      end

      tests.each do |test|
        marks_earned += test['marks_earned'].to_i
        new_test_script_result.test_results.create(
          name: test['name'],
          repo_revision: revision_number,
          input: (test['input'].nil? ? '' : test['input']),
          actual_output: (test['actual'].nil? ? '' : test['actual']),
          expected_output: (test['expected'].nil? ? '' : test['expected']),         
          marks_earned: test['marks_earned'].to_i,
          completion_status: test['status'])
      end
      new_test_script_result.marks_earned = marks_earned
      new_test_script_result.save!
    end

    if (call_on == 'collection' || call_on == 'submission')
      grouping.current_submission_used.set_marks_for_tests
    end

  end
end
