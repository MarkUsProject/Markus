module AutomatedTestsClientHelper

  ASSIGNMENTS_DIR = File.join(MarkusConfigurator.autotest_client_dir, 'assignments')
  STUDENTS_DIR = File.join(MarkusConfigurator.autotest_client_dir, 'students')

  def create_test_repo(assignment)
    test_dir = File.join(ASSIGNMENTS_DIR, assignment.short_identifier)
    unless File.exist?(test_dir)
      FileUtils.mkdir_p(test_dir)
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
        raise I18n.t('automated_tests.duplicate_filename') + new_file_name
      end
      updated_form_file[:file_name] = new_file_name
      new_file_path = File.join(ASSIGNMENTS_DIR, assignment.short_identifier, new_file_name)
      files.push({path: new_file_path, upload: new_file})
    # 5) Possibly replace existing test file
    else
      return updated_form_file unless form_file[:file_name].nil? # replacing a test file resets the old name
      old_file_name = model_class.find(form_file[:id]).file_name
      upd_file = params[("#{upd_name}_#{old_file_name}").to_sym]
      upd_file_name = upd_file.original_filename
      updated_form_file[:file_name] = upd_file_name
      mod_file_path = File.join(ASSIGNMENTS_DIR, assignment.short_identifier, upd_file_name)
      f = {path: mod_file_path, upload: upd_file}
      unless upd_file_name == old_file_name
        old_file_path = File.join(ASSIGNMENTS_DIR, assignment.short_identifier, old_file_name)
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

  def self.get_test_server_user
    test_server_host = MarkusConfigurator.autotest_server_host
    test_server_user = User.find_by(user_name: test_server_host)
    if test_server_user.nil? || !test_server_user.test_server?
      raise I18n.t('automated_tests.error.no_test_server_user', { hostname: test_server_host })
    end
    test_server_user.set_api_key

    test_server_user
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
      raise I18n.t('automated_tests.error.ta_not_allowed')
    end
    # student checks from now on

    # student tests enabled
    unless MarkusConfigurator.autotest_student_tests_on?
      raise I18n.t('automated_tests.error.not_enabled')
    end
    # student belongs to the grouping
    unless user.accepted_groupings.include?(grouping)
      raise I18n.t('automated_tests.error.bad_group')
    end
    # deadline has not passed
    if grouping.assignment.submission_rule.can_collect_now?
      raise I18n.t('automated_tests.error.after_due_date')
    end
    token = grouping.prepare_tokens_to_use
    # no other enqueued tests
    if token.enqueued?
      raise I18n.t('automated_tests.error.already_enqueued')
    end
    token.decrease_tokens # raises exception with no tokens available
  end

  # Verify that MarkUs has test scripts to run the test and get them.
  def self.get_test_scripts(assignment, user)

    # No test directory or test files
    test_dir = File.join(ASSIGNMENTS_DIR, assignment.short_identifier)
    unless File.exist?(test_dir)
      raise I18n.t('automated_tests.error.no_test_files')
    end

    # Select a subset of test scripts
    if user.admin?
      test_scripts = assignment.instructor_test_scripts
                               .order(:seq_num)
                               .pluck(:file_name, :timeout)
    elsif user.student?
      test_scripts = assignment.student_test_scripts
                               .order(:seq_num)
                               .pluck(:file_name, :timeout)
    else
      test_scripts = []
    end
    if test_scripts.empty?
      raise I18n.t('automated_tests.error.no_test_files')
    end

    test_scripts.to_h
  end

  def self.request_a_test_run(host_with_port, current_user, test_runs)

    #TODO everything here is just authorization stuff to be extracted in policies
    grouping_id = test_runs[0][:grouping_id]
    grouping = Grouping.find(grouping_id)
    assignment = grouping.assignment
    unless assignment.enable_test
      raise I18n.t('automated_tests.error.not_enabled')
    end
    test_server_user = get_test_server_user
    test_scripts = get_test_scripts(assignment, current_user)
    check_user_permission(current_user, grouping)

    # if current_user is an instructor, then a submission exists and we use that repo revision
    # if current_user is a student, then we use the latest repo revision
    AutotestRunJob.perform_later(host_with_port, test_scripts, current_user.api_key, test_server_user.api_key, test_runs)
  end

end
