require 'net/ssh'
require 'net/scp'
require 'json'

module AutomatedTestsClientHelper
  # This is the waiting list for automated testing on the test client. Once a test is requested, it is enqueued
  # and it is waiting for the submission files to be copied in the test location. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_file_queue_name

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

  # Verify that MarkUs has some files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one test script and
  # source files are successfully exported.
  def self.test_files_available?(assignment, repo_dir)

    # TODO: show the errors to the user instead of raising a runtime error
    # No test files or test directory
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)
    if TestScript.find_by(assignment_id: assignment.id).nil? || !File.exist?(test_dir)
      raise I18n.t('automated_tests.test_files_unavailable')
    end
    # No assignment directory or no files in repo (only current and parent directory pointers)
    assignment_dir = File.join(repo_dir, assignment.repository_folder)
    if !File.exist?(assignment_dir) || Dir.entries(assignment_dir).length <= 2
      raise I18n.t('automated_tests.source_files_unavailable')
    end

    return true
  end

  # Verify the user has the permission to run the tests - admin
  # and graders always have the permission, while student has to
  # belong to the group, and have at least one token.
  def self.user_has_permission?(user, grouping, assignment)

    # TODO: show the errors to the user instead of raising a runtime error
    if user.admin? || user.ta?
      return true
    end
    # Make sure student belongs to this group
    unless user.accepted_groupings.include?(grouping)
      raise I18n.t('automated_tests.not_belong_to_group')
    end
    # can skip checking tokens if we have unlimited
    if assignment.unlimited_tokens
      return true
    end
    t = grouping.token
    if t.nil? || t.remaining <= 0
      raise I18n.t('automated_tests.missing_tokens')
    end
    t.decrease_tokens

    return true
  end

  def self.request_a_test_run(host_with_port, grouping_id, call_on, current_user, submission_id = nil)

    # TODO Show errors to the user rather than just logging them? (and where is the logger logging?)
    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    group = grouping.group
    repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, group.repo_name)

    # TODO export the right repo revision using submission_id
    # TODO Restore call to run tests when collecting submission
    export_group_repo(group, repo_dir)
    if test_files_available?(assignment, repo_dir) &&
       (call_on == 'collection' || user_has_permission?(current_user, grouping, assignment))
      Resque.enqueue(AutomatedTestsClientHelper, host_with_port, grouping_id, call_on, current_user.api_key, submission_id)
    end
  end

  # Find the list of test scripts to run the test. Return the list of
  # test scripts in the order specified by seq_num (running order)
  def self.get_test_scripts_to_run(assignment, call_on)

    all_scripts = TestScript.where(assignment_id: assignment.id)
    # If the test run is requested at collection (by Admin or TA),
    # All of the test scripts should be run.
    if call_on == 'collection'
      test_scripts = all_scripts
    elsif call_on == 'submission'
      test_scripts = all_scripts.select(&:run_on_submission)
    elsif call_on == 'request'
      test_scripts = all_scripts.select(&:run_on_request)
    else
      test_scripts = []
    end

    return test_scripts.sort_by(&:seq_num)
  end

  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  def self.perform(host_with_port, grouping_id, call_on, api_key, submission_id = nil)

    # TODO is submission_id needed?
    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    group = grouping.group
    submission_path = File.join(MarkusConfigurator.markus_config_automated_tests_repository, group.repo_name, assignment.repository_folder)
    assignment_tests_path = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.repository_folder)
    test_results_path = MarkusConfigurator.markus_ate_test_server_results_dir
    markus_address = host_with_port.start_with?('localhost') ? "http://#{host_with_port}" : "https://#{host_with_port}"
    test_server_host = MarkusConfigurator.markus_ate_test_server_host

    test_scripts = get_test_scripts_to_run(assignment, call_on)
    test_scripts.map! do |script|
      script.script_name
    end

    if test_server_host == 'localhost'
      # tests executed locally: create a clean folder, copying the student's submission and all necessary test files
      test_path = File.join(MarkusConfigurator.markus_config_automated_tests_repository, 'test')
      test_scripts_executables = test_scripts.map {|s| "chmod u+x '#{test_path}/#{s}'"}.join(' && ')
      stdout, stderr, status = Open3.capture3("
        rm -rf '#{test_path}' &&
        mkdir '#{test_path}' &&
        cp -r '#{submission_path}'/* '#{test_path}' &&
        cp -r '#{assignment_tests_path}'/* '#{test_path}' &&
        #{test_scripts_executables}
      ")
      unless status.success?
        MarkusLogger.instance.log("ATE local test copy error for assignment #{assignment}, group #{grouping}:\n
                                  out: #{stdout}\nerr: #{stderr}", MarkusLogger::ERROR)
        return
      end
      # enqueue locally using api
      Resque.enqueue(AutomatedTestsServerHelper, markus_address, api_key, test_scripts, test_path, test_results_path, assignment.id, group.id)
    else
      # tests executed on a test server: copy the student's submission and all necessary files through ssh
      test_server_username = MarkusConfigurator.markus_ate_test_server_username
      queue = MarkusConfigurator.markus_ate_test_queue_name
      begin
        Net::SSH::start(test_server_host, test_server_username) do |ssh|
          test_path = ssh.exec!('mktemp -d').strip
          Dir.foreach(submission_path) do |file_name| # workaround scp not supporting wildcard *
            next if file_name == '.' or file_name == '..'
            file_path = File.join(submission_path, file_name)
            options = File.directory?(file_path) ? {:recursive => true} : {}
            ssh.scp.upload!(file_path, test_path, options)
          end
          Dir.foreach(assignment_tests_path) do |file_name| # workaround scp not supporting wildcard *
            next if file_name == '.' or file_name == '..'
            file_path = File.join(assignment_tests_path, file_name)
            ssh.scp.upload!(file_path, test_path)
          end
          # TODO brutal, think about sandboxing
          ssh.exec!("chmod -R o+rwx '#{test_path}'")
          # enqueue remotely directly in redis, resque does not allow for multiple redis servers
          resque_params = {:class => 'AutomatedTestsServerHelper',
                           :args => [markus_address, api_key, test_scripts, test_path, test_results_path, assignment.id,
                                     group.id]}
          ssh.exec!("redis-cli rpush \"resque:queue:#{queue}\" '#{JSON.generate(resque_params)}'")
        end
      rescue Exception => e
        MarkusLogger.instance.log("ATE remote ssh error for assignment #{assignment}, group #{grouping}:\n
                                  #{e.message}", MarkusLogger::ERROR)
      end
    end
  end

  def self.process_test_result(raw_result, call_on, assignment, grouping, submission = nil)

    # TODO need to pass call_on through the api
    result = Hash.from_xml(raw_result)
    repo = grouping.group.repo
    revision = repo.get_latest_revision
    revision_number = revision.revision_number
    submission_id = submission ? submission.id : nil

    # Hash.from_xml will yield a hash with only one test script and an array otherwise
    test_scripts = result['testrun']['test_script']
    if test_scripts.nil?
      MarkusLogger.instance.log("ATE test run framework error for assignment #{assignment}, group #{grouping}:\n
                                 #{raw_result}", MarkusLogger::ERROR)
      return
    end
    unless test_scripts.is_a?(Array)
      test_scripts = [test_scripts]
    end

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

      # same workaround as above, Hash.from_xml produces a hash if it's a single test
      tests = script['test']
      if tests.nil?
        MarkusLogger.instance.log("ATE test run error for script #{script_name}, assignment #{assignment},
                                   group #{grouping}:\n#{script}", MarkusLogger::ERROR)
        tests = []
      end
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

    if call_on == 'collection' || call_on == 'submission'
      grouping.current_submission_used.set_marks_for_tests
    end

  end

end
