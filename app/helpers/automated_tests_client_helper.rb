module AutomatedTestsClientHelper

  ASSIGNMENTS_DIR = File.join(MarkusConfigurator.autotest_client_dir, 'assignments')
  STUDENTS_DIR = File.join(MarkusConfigurator.autotest_client_dir, 'students')
  HOOKS_FILE = 'hooks.py'.freeze

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
      f = { path: new_file_path, upload: new_file }
    # 5) Possibly replace existing test file
    else
      return updated_form_file unless form_file[:file_name].nil? # replacing a test file resets the old name
      old_file_name = model_class.find(form_file[:id]).file_name
      upd_file = params[("#{upd_name}_#{old_file_name}").to_sym]
      upd_file_name = upd_file.original_filename
      updated_form_file[:file_name] = upd_file_name
      mod_file_path = File.join(ASSIGNMENTS_DIR, assignment.short_identifier, upd_file_name)
      f = { path: mod_file_path, upload: upd_file }
      unless upd_file_name == old_file_name
        old_file_path = File.join(ASSIGNMENTS_DIR, assignment.short_identifier, old_file_name)
        f[:delete] = old_file_path
      end
    end
    files.push(f)

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

  # TODO: Move the following to model-based policies
  def self.allowed_to?(user, **checks)
    # AutotestPolicy
    if user.ta?
      return false, I18n.t('automated_tests.error.no_tas')
    end
    assignment = checks[:assignment]
    unless assignment.nil?
      # AssignmentPolicy < AutotestPolicy
      unless assignment.enable_test
        return false, I18n.t('automated_tests.error.not_enabled')
      end
      if user.student?
        unless assignment.enable_student_tests
          return false, I18n.t('automated_tests.error.not_enabled')
        end
        if Time.current < assignment.token_start_date
          return false, I18n.t('automated_tests.error.no_tokens_yet')
        end
        if assignment.submission_rule.can_collect_now?
          return false, I18n.t('automated_tests.error.after_due_date')
        end
      end
      unless assignment.select_test_scripts(user).exists?
        return false, I18n.t('automated_tests.error.no_test_files')
      end
    end
    submission = checks[:submission]
    unless submission.nil?
      # SubmissionPolicy < AutotestPolicy
      if submission.current_result.released_to_students
        return false, I18n.t('automated_tests.error.after_release')
      end
    end
    grouping = checks[:grouping]
    unless grouping.nil?
      # GroupingPolicy < AutotestPolicy
      # TODO: Investigate !grouping.is_valid? in refresh_test_tokens
      if user.student?
        unless grouping.accepted_students.include?(user)
          return false, I18n.t('automated_tests.error.bad_group')
        end
        if grouping.student_test_run_in_progress?
          return false, I18n.t('automated_tests.error.already_enqueued')
        end
        if grouping.test_tokens <= 0 && !grouping.assignment.unlimited_tokens
          return false, I18n.t('automated_tests.error.no_tokens')
        end
      end
    end
    return true, ''
  end

  def self.authorize!(user, **checks)
    authorized, reason = AutomatedTestsClientHelper.allowed_to?(user, **checks)
    unless authorized
      raise reason
    end
  end

end
