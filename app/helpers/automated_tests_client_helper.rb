module AutomatedTestsClientHelper
  # This is the waiting list for automated testing on the test client. Once a test is requested, it is enqueued
  # and it is waiting for the submission files to be copied in the test location. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_files_queue_name

  def create_test_repo(assignment)
    # Create the automated test repository
    unless File.exist?(MarkusConfigurator.markus_ate_client_dir)
      FileUtils.mkdir(MarkusConfigurator.markus_ate_client_dir)
    end
    test_dir = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.short_identifier)
    unless File.exist?(test_dir)
      FileUtils.mkdir(test_dir)
    end
  end

  def process_test_file(assignment, params, files, form_file, is_script)

    # custom variables
    if is_script
      new_file_param = :new_script
      model_class = TestScript
      upd_name = 'new_update_script'
    else
      new_file_param = :new_support_file
      model_class = TestSupportFile
      upd_name = 'new_update_file'
    end

    # 1) Remove existing test file
    if form_file[:_destroy] == '1'
      return form_file.clone # the _destroy flag will be processed with save
    end
    # 2) Empty form
    is_new = form_file[:id].nil? # id is non-nil only for existing test files
    new_file = params[new_file_param]
    return nil if is_new && new_file.nil?
    # 3) Always update test file options (both new and existing test files)
    updated_form_file = form_file.clone
    if is_script
      if form_file[:criterion_id].empty?
        updated_form_file[:criterion_id] = nil
        updated_form_file[:criterion_type] = nil
      else
        crit_id, crit_type = JSON.parse(form_file[:criterion_id]) # "[id, "type"]"
        updated_form_file[:criterion_id] = crit_id
        updated_form_file[:criterion_type] = crit_type
      end
    end
    # 4) Create new test file
    if is_new
      new_file_name = new_file.original_filename
      if model_class.exists?(file_name: new_file_name, assignment: assignment)
        raise t('automated_tests.duplicate_filename') + new_file_name
      end
      updated_form_file[:file_name] = new_file_name
      new_file_path = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.repository_folder, new_file_name)
      files.push({path: new_file_path, upload: new_file})
    # 5) Possibly replace existing test file
    else
      return updated_form_file unless form_file[:file_name].nil? # replacing a test file resets the old name
      old_file_name = model_class.find(form_file[:id]).file_name
      upd_file = params[("#{upd_name}_#{old_file_name}").to_sym]
      upd_file_name = upd_file.original_filename
      updated_form_file[:file_name] = upd_file_name
      mod_file_path = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.repository_folder, upd_file_name)
      f = {path: mod_file_path, upload: upd_file}
      unless upd_file_name == old_file_name
        old_file_path = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.repository_folder, old_file_name)
        f[:delete] = old_file_path
      end
      files.push(f)
    end

    updated_form_file
  end

  # Process Testing Framework form
  # - Process new and updated test files (additional validation to be done at the model level)
  def process_test_form(assignment, params, assignment_params)

    files = []

    # Create/Update test scripts
    scripts = assignment_params[:test_scripts_attributes] || []
    updated_scripts = {}
    scripts.each do |i, script|
      updated_script = process_test_file(assignment, params, files, script, true)
      next if updated_script.nil?
      updated_script[:seq_num] = i
      updated_scripts[i] = updated_script
    end

    # Create/Update test support files
    supporters = assignment_params[:test_support_files_attributes] || []
    updated_supporters = {}
    supporters.each do |i, supporter|
      updated_supporter = process_test_file(assignment, params, files, supporter, false)
      next if updated_supporter.nil?
      updated_supporters[i] = updated_supporter
    end

    # Update test file attributes
    assignment.test_scripts_attributes = updated_scripts
    assignment.test_support_files_attributes = updated_supporters

    assignment.enable_test = assignment_params[:enable_test]
    assignment.enable_student_tests = assignment_params[:enable_student_tests]
    assignment.non_regenerating_tokens = assignment_params[:non_regenerating_tokens]
    assignment.unlimited_tokens = assignment_params[:unlimited_tokens]
    assignment.token_start_date = assignment_params[:token_start_date]
    assignment.token_period = assignment_params[:token_period]
    assignment.tokens_per_period = assignment_params[:tokens_per_period].nil? ?
                                     0 : assignment_params[:tokens_per_period]

    files
  end

  # Export group repository for testing. Students' submitted files
  # are stored in the group repository. They must be exported
  # before copying to the test server.
  def self.export_group_repo(group, repo_dir, submission = nil)

    # Create the automated test repository
    unless File.exists?(MarkusConfigurator.markus_ate_client_dir)
      FileUtils.mkdir(MarkusConfigurator.markus_ate_client_dir)
    end
    # Delete student's assignment repository if it already exists
    # TODO clean up in client worker, or try to optimize if revision is the same?
    if File.exists?(repo_dir)
      FileUtils.rm_rf(repo_dir)
    end
    # Export the correct repo revision
    if submission.nil?
      group.repo.export(repo_dir)
    else
      files = submission.submission_files
      FileUtils.mkdir(repo_dir)
      files.each do |file|
        file_content = file.retrieve_file
        FileUtils.mkdir_p(File.join(repo_dir, file.path))
        File.open(File.join(repo_dir, file.path, file.filename), 'wb') do |f| # binary write to avoid encoding issues
          f.write(file_content)
        end
      end
    end
  end

  def self.get_test_server_user
    test_server_host = MarkusConfigurator.markus_ate_server_host
    test_server_user = User.find_by(user_name: test_server_host)
    if test_server_user.nil? || !test_server_user.test_server?
      raise t('automated_tests.error.no_test_server_user', {hostname: test_server_host})
    end
    test_server_user.set_api_key

    return test_server_user
  end

  # Verify the user has the permission to run the tests - admins
  # always have the permission, while student has to
  # belong to the group, and have at least one token.
  def self.check_user_permission(user, grouping)

    # the user may not have an api key yet
    user.set_api_key
    # admins are always ok
    if user.admin?
      return
    end
    # no tas
    if user.ta?
      raise t('automated_tests.error.ta_not_allowed')
    end
    # student checks from now on

    # student tests enabled
    unless MarkusConfigurator.markus_ate_student_tests_on?
      raise t('automated_tests.error.not_enabled')
    end
    # student belongs to the grouping
    unless user.accepted_groupings.include?(grouping)
      raise t('automated_tests.error.bad_group')
    end
    # deadline has not passed
    if grouping.assignment.submission_rule.can_collect_now?
      raise t('automated_tests.error.after_due_date')
    end
    token = grouping.prepare_tokens_to_use
    # no other enqueued tests
    if token.enqueued?
      raise t('automated_tests.error.already_enqueued')
    end
    token.decrease_tokens # raises exception with no tokens available
  end

  # Verify that MarkUs has test scripts to run the test and get them.
  def self.get_test_scripts(assignment, user)

    # No test directory or test files
    test_dir = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.short_identifier)
    unless File.exist?(test_dir)
      raise t('automated_tests.error.no_test_files')
    end

    # Select a subset of test scripts
    if user.admin?
      test_scripts = assignment.instructor_test_scripts
                               .order(:seq_num)
                               .pluck_to_hash(:file_name, :timeout)
    elsif user.student?
      test_scripts = assignment.student_test_scripts
                               .order(:seq_num)
                               .pluck_to_hash(:file_name, :timeout)
    else
      test_scripts = []
    end
    if test_scripts.empty?
      raise t('automated_tests.error.no_test_files')
    end

    test_scripts
  end

  def self.request_a_test_run(host_with_port, grouping_id, current_user, submission_id = nil)

    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    unless assignment.enable_test
      raise t('automated_tests.error.not_enabled')
    end
    test_server_user = get_test_server_user
    test_scripts = get_test_scripts(assignment, current_user)
    check_user_permission(current_user, grouping)

    # if current_user is an instructor, then a submission exists and we use that repo revision
    # if current_user is a student, then we use the latest repo revision
    group = grouping.group
    repo_dir = File.join(MarkusConfigurator.markus_ate_client_dir, group.repo_name)
    submission = submission_id.nil? ? nil : Submission.find(submission_id)
    export_group_repo(group, repo_dir, submission)
    Resque.enqueue(AutomatedTestsClientHelper, host_with_port, test_scripts, current_user.api_key,
                   test_server_user.api_key, grouping_id, submission_id)
  end

  # Verify that MarkUs has student files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one source file is successfully exported.
  def self.repo_files_available?(assignment, repo_dir)
    # No assignment directory or no files in repo (only current and parent directory pointers)
    assignment_dir = File.join(repo_dir, assignment.repository_folder)
    if !File.exist?(assignment_dir) || Dir.entries(assignment_dir).length <= 2
      return false
    end

    return true
  end

  def self.get_concurrent_tests_config
    server_tests_config = MarkusConfigurator.markus_ate_server_tests
    i = 0
    if server_tests_config.length > 1 # concurrent tests for real
      i = Rails.cache.fetch('ate_server_tests_i') { 0 }
      next_i = (i + 1) % server_tests_config.length # use a round robin strategy
      Rails.cache.write('ate_server_tests_i', next_i)
    end
    server_tests_config[i]
  end

  def self.create_test_script_result(file_name, assignment, grouping, submission, requested_by, time)
    revision_identifier = submission.nil? ?
        grouping.group.repo.get_latest_revision.revision_identifier :
        submission.revision_identifier
    submission_id = submission.nil? ? nil : submission.id
    test_script = TestScript.find_by(assignment_id: assignment.id, file_name: file_name)

    return grouping.test_script_results.create(
        test_script_id: test_script.id,
        submission_id: submission_id,
        marks_earned: 0.0,
        marks_total: 0.0,
        repo_revision: revision_identifier,
        requested_by_id: requested_by.id,
        time: time)
  end

  def self.create_all_test_scripts_error_result(test_scripts, assignment, grouping, submission, requested_by,
                                                result_name, result_message)
    test_scripts.each do |file_name|
      test_script_result = create_test_script_result(file_name, assignment, grouping, submission, requested_by, 0)
      test_script_result.add_test_error_result(result_name, result_message)
      test_script_result.save
    end
    unless submission.nil?
      submission.set_marks_for_tests
    end
  end

  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  def self.perform(host_with_port, test_scripts, user_api_key, server_api_key, grouping_id, submission_id)

    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    group = grouping.group

    # create empty test results for no submission files
    repo_dir = File.join(MarkusConfigurator.markus_ate_client_dir, group.repo_name)
    unless repo_files_available?(assignment, repo_dir)
      submission = submission_id.nil? ? nil : Submission.find(submission_id)
      requested_by = User.find_by(api_key: user_api_key)
      create_all_test_scripts_error_result(test_scripts.map {|s| s['file_name']}, assignment, grouping, submission,
                                           requested_by, t('automated_tests.test_result.all_tests'),
                                           t('automated_tests.test_result.no_source_files'))
      return
    end

    submission_path = File.join(repo_dir, assignment.repository_folder)
    assignment_tests_path = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.repository_folder)
    markus_address = Rails.application.config.action_controller.relative_url_root.nil? ?
        host_with_port :
        host_with_port + Rails.application.config.action_controller.relative_url_root
    test_server_host = MarkusConfigurator.markus_ate_server_host
    test_server_user = User.find_by(user_name: test_server_host)
    if test_server_user.nil?
      return
    end
    tests_config = get_concurrent_tests_config
    files_path = MarkusConfigurator.markus_ate_server_files_dir
    results_path = MarkusConfigurator.markus_ate_server_results_dir
    file_username = MarkusConfigurator.markus_ate_server_files_username
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
      create_all_test_scripts_error_result(test_scripts.map {|s| s['file_name']}, assignment, grouping, submission,
                                           requested_by, t('automated_tests.test_result.all_tests'),
                                           t('automated_tests.test_result.bad_server',
                                             {hostname: test_server_host, error: e.message}))
    end
  end

  def self.process_test_script_result(xml, assignment, grouping, submission, requested_by)

    # create test result
    file_name = xml['file_name']
    time = xml['time'].nil? ? 0 : xml['time']
    new_test_script_result = create_test_script_result(file_name, assignment, grouping, submission, requested_by, time)
    tests = xml['test']
    if tests.nil?
      new_test_script_result.add_test_error_result(t('automated_tests.test_result.all_tests'),
                                                   t('automated_tests.test_result.no_tests'))
      return new_test_script_result
    end
    unless tests.is_a?(Array) # same workaround as above, Hash.from_xml returns a hash if it's a single test
      tests = [tests]
    end

    # process tests
    all_marks_earned = 0.0
    all_marks_total = 0.0
    tests.each do |test|
      begin
        marks_earned, marks_total = new_test_script_result.add_test_result_from_xml(test)
      rescue
        # with malformed xml, test results could be valid only up to a certain test
        # similarly, the test script can signal a serious failure that requires stopping and assigning zero marks
        all_marks_earned = 0.0
        break
      end
      all_marks_earned += marks_earned
      all_marks_total += marks_total
    end
    new_test_script_result.marks_earned = all_marks_earned
    new_test_script_result.marks_total = all_marks_total
    new_test_script_result.save

    new_test_script_result
  end

  def self.process_test_run(assignment, grouping, submission, requested_by, test_scripts_ran, test_output_xml,
                            test_errors=nil)

    # check unhandled errors first, but don't stop here
    unless test_errors.blank?
      create_all_test_scripts_error_result(test_scripts_ran, assignment, grouping, submission, requested_by,
                                           t('automated_tests.test_result.all_tests'),
                                           t('automated_tests.test_result.err_results', {errors: test_errors}))
    end
    # check that results are somewhat well-formed xml at the top level (i.e. they don't crash the parser)
    xml = nil
    begin
      xml = Hash.from_xml(test_output_xml)
    rescue => e
      create_all_test_scripts_error_result(test_scripts_ran, assignment, grouping, submission, requested_by,
                                           t('automated_tests.test_result.all_tests'),
                                           t('automated_tests.test_result.bad_results', {xml: e.message}))
      return
    end
    test_run = xml['testrun']
    test_scripts = test_run.nil? ? nil : test_run['test_script']
    if test_run.nil? || test_scripts.nil?
      create_all_test_scripts_error_result(test_scripts_ran, assignment, grouping, submission, requested_by,
                                           t('automated_tests.test_result.all_tests'),
                                           t('automated_tests.test_result.bad_results', {xml: xml}))
      return
    end

    # process results
    unless test_scripts.is_a?(Array) # Hash.from_xml returns a hash if it's a single test script and an array otherwise
      test_scripts = [test_scripts]
    end
    new_test_script_results = {}
    test_scripts.each do |test_script|
      file_name = test_script['file_name']
      if file_name.nil? # with malformed xml, some test script results could be valid and some won't, recover later
        next
      end
      new_test_script_result = AutomatedTestsClientHelper.process_test_script_result(test_script, assignment, grouping,
                                                                                     submission, requested_by)
      new_test_script_results[file_name] = new_test_script_result
    end

    # try to recover from malformed xml at the test script level
    test_scripts_ran.each do |file_name|
      if new_test_script_results[file_name].nil?
        new_test_script_result = create_test_script_result(file_name, assignment, grouping, submission, requested_by, 0)
        new_test_script_result.add_test_error_result(t('automated_tests.test_result.all_tests'),
                                                     t('automated_tests.test_result.bad_results', {xml: xml}))
      end
    end

    # set the marks assigned by the test
    unless submission.nil?
      submission.set_marks_for_tests
    end
  end

end
