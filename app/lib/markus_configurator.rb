# ApplicationRecord mixin to configure MarkUs
# All descendants have the following methods available

module MarkusConfigurator

  ######################################
  # Repository configuration
  ######################################
  def self.markus_config_repository_admin?
    if defined? IS_REPOSITORY_ADMIN
      return IS_REPOSITORY_ADMIN
    else
      #If not defined, default to true
      return true
    end
  end

  def self.markus_config_repository_hooks
    if defined? REPOSITORY_HOOKS && Rails.configuration.x.repository.type == 'git'
      REPOSITORY_HOOKS
    else
      {}
    end
  end

  def self.markus_config_repository_client_hooks
    if defined? REPOSITORY_CLIENT_HOOKS && Rails.configuration.x.repository.type == 'git'
      REPOSITORY_CLIENT_HOOKS
    else
      ''
    end
  end

  def self.markus_config_pdf_conv_memory_allowance
    if defined? PDF_CONV_MEMORY_ALLOWANCE
      return PDF_CONV_MEMORY_ALLOWANCE
    else
      return 100
    end
  end

  def self.markus_config_repository_external_base_url
    if defined? REPOSITORY_EXTERNAL_BASE_URL
      return REPOSITORY_EXTERNAL_BASE_URL
    else
      return 'http://www.example.com/git'
    end
  end

  def self.markus_config_repository_external_submits_only?
    case Rails.configuration.x.repository.type
    when 'svn'
        if defined? REPOSITORY_EXTERNAL_SUBMITS_ONLY
          retval = REPOSITORY_EXTERNAL_SUBMITS_ONLY
        else
          retval = false
        end
      else
        retval = false
    end
    return retval
  end

  def self.markus_config_logout_redirect
    if defined? LOGOUT_REDIRECT
      return LOGOUT_REDIRECT
    else
      return "DEFAULT"
    end
  end

  def self.markus_config_validate_user_message
    if defined? VALIDATE_USER_NOT_ALLOWED_DISPLAY
      return VALIDATE_USER_NOT_ALLOWED_DISPLAY
    else
      return nil
    end
  end

  def self.markus_config_validate_login_message
    if defined? VALIDATE_LOGIN_INCORRECT_DISPLAY
      return VALIDATE_LOGIN_INCORRECT_DISPLAY
    else
      return nil
    end
  end

  ######################################
  # MarkusLogger configuration
  ######################################
  def self.markus_config_logging_enabled?
    if defined? MARKUS_LOGGING_ENABLED
      return MARKUS_LOGGING_ENABLED
    else
      #If not defined, default to true
      return true
    end
  end

  def self.markus_config_logging_rotate_by_interval
    if defined? MARKUS_LOGGING_ROTATE_BY_INTERVAL
      return MARKUS_LOGGING_ROTATE_BY_INTERVAL
    else
      return false
    end
  end

  def self.markus_config_logging_size_threshold
    if defined? MARKUS_LOGGING_SIZE_THRESHOLD
      return MARKUS_LOGGING_SIZE_THRESHOLD
    else
      return (1024 * 10**6)
    end
  end

  def self.markus_config_logging_rotate_interval
    if defined? MARKUS_LOGGING_ROTATE_INTERVAL
      return MARKUS_LOGGING_ROTATE_INTERVAL
    else
      return 'daily'
    end
  end

  def self.markus_config_logging_logfile
    if defined? MARKUS_LOGGING_LOGFILE
      return MARKUS_LOGGING_LOGFILE
    else
      return File.join(::Rails.root.to_s, "log", "#{::Rails.env}_info.log")
    end
  end

  def self.markus_config_logging_errorlogfile
    if defined? MARKUS_LOGGING_ERRORLOGFILE
      return MARKUS_LOGGING_ERRORLOGFILE
    else
      return File.join(::Rails.root.to_s, "log", "#{::Rails.env}_error.log")
    end
  end

  def self.markus_config_logging_num_oldfiles
    if defined? MARKUS_LOGGING_OLDFILES
      return MARKUS_LOGGING_OLDFILES
    else
      return 10
    end
  end

  ##########################################
  # Automated Testing Engine Configuration
  ##########################################

  def self.autotest_on?
    (defined? AUTOTEST_ON) && AUTOTEST_ON == true
  end

  def self.autotest_student_tests_on?
    if autotest_on? && (defined? AUTOTEST_STUDENT_TESTS_ON)
      AUTOTEST_STUDENT_TESTS_ON
    else
      false
    end
  end

  def self.autotest_student_tests_buffer_time
    if autotest_student_tests_on? && (defined? AUTOTEST_STUDENT_TESTS_BUFFER_TIME)
      AUTOTEST_STUDENT_TESTS_BUFFER_TIME
    else
      1.hour
    end
  end

  def self.autotest_client_dir
    if autotest_on? && (defined? AUTOTEST_CLIENT_DIR)
      AUTOTEST_CLIENT_DIR
    else
      File.join(::Rails.root.to_s, 'autotest')
    end
  end

  def self.autotest_server_host
    if autotest_on? && (defined? AUTOTEST_SERVER_HOST)
      AUTOTEST_SERVER_HOST
    else
      'localhost'
    end
  end

  def self.autotest_server_username
    if autotest_on? && (defined? AUTOTEST_SERVER_USERNAME)
      AUTOTEST_SERVER_USERNAME
    else
      nil
    end
  end

  def self.autotest_server_dir
    if autotest_on? && (defined? AUTOTEST_SERVER_DIR)
      AUTOTEST_SERVER_DIR
    else
      File.join(::Rails.root.to_s, 'autotest', 'server')
    end
  end

  def self.autotest_server_command
    if autotest_on? && (defined? AUTOTEST_SERVER_COMMAND)
      AUTOTEST_SERVER_COMMAND
    else
      'enqueuer'
    end
  end

  def self.autotest_run_queue
    if autotest_on? && (defined? AUTOTEST_RUN_QUEUE)
      AUTOTEST_RUN_QUEUE
    else
      'jobs'
    end
  end

  def self.autotest_cancel_queue
    if autotest_on? && (defined? AUTOTEST_CANCEL_QUEUE)
      AUTOTEST_CANCEL_QUEUE
    else
      'jobs'
    end
  end

  def self.autotest_specs_queue
    if autotest_on? && (defined? AUTOTEST_SPECS_QUEUE)
      AUTOTEST_SPECS_QUEUE
    else
      'jobs'
    end
  end

  def self.autotest_testers_queue
    if autotest_on? && (defined? AUTOTEST_TESTERS_QUEUE)
      AUTOTEST_TESTERS_QUEUE
    else
      'jobs'
    end
  end

  ###################################################################
  # Starter code configuration
  ###################################################################
  # Global flag to enable/disable starter code feature.
  def self.markus_starter_code_on
    if defined? STARTER_CODE_ON
      STARTER_CODE_ON
    else
      false
    end
  end

  ###################################################################
  # Exam Plugin configuration
  ###################################################################
  # Global flag to enable/disable all exam plugin features.
  def self.markus_exam_plugin_on
    if defined? EXPERIMENTAL_EXAM_PLUGIN_ON
      EXPERIMENTAL_EXAM_PLUGIN_ON
    else
      false
    end
  end

  def self.markus_exam_template_dir
    if defined? EXAM_TEMPLATE_DIR
      EXAM_TEMPLATE_DIR
    else
      File.join(::Rails.root.to_s, 'data', 'dev', 'exam_templates')
    end
  end

  # Whether to allow the creation of scanned exams
  def self.markus_experimental_scanned_exam_on?
    if defined? EXPERIMENTAL_EXAM_PLUGIN_ON
      EXPERIMENTAL_EXAM_PLUGIN_ON
    else
      false
    end
  end

  def self.markus_exam_python_executable
    if defined? EXAM_PYTHON_EXE
      EXAM_PYTHON_EXE
    else
      'python'
    end
  end

  ##########################################
  # Resque Configuration
  ##########################################

  def self.markus_job_create_groups_queue_name
    if defined? JOB_CREATE_GROUPS_QUEUE_NAME
      JOB_CREATE_GROUPS_QUEUE_NAME
    else
      'jobs'
    end
  end

  def self.markus_job_collect_submissions_queue_name
    if defined? JOB_COLLECT_SUBMISSIONS_QUEUE_NAME
      JOB_COLLECT_SUBMISSIONS_QUEUE_NAME
    else
      'jobs'
    end
  end

  def self.markus_job_uncollect_submissions_queue_name
    if defined? JOB_UNCOLLECT_SUBMISSIONS_QUEUE_NAME
      JOB_UNCOLLECT_SUBMISSIONS_QUEUE_NAME
    else
      'jobs'
    end
  end

  def self.markus_job_update_repo_required_files_queue_name
    if defined? JOB_UPDATE_REPO_REQUIRED_FILES_QUEUE_NAME
      JOB_UPDATE_REPO_REQUIRED_FILES_QUEUE_NAME
    else
      'jobs'
    end
  end

  def self.markus_job_generate_queue_name
    if defined? JOB_GENERATE_QUEUE_NAME
      JOB_GENERATE_QUEUE_NAME
    else
      'jobs'
    end
  end

  def self.markus_job_split_pdf_queue_name
    if defined? JOB_SPLIT_PDF_QUEUE_NAME
      JOB_SPLIT_PDF_QUEUE_NAME
    else
      'jobs'
    end
  end

  def self.markus_job_update_starter_code_queue
    if defined? JOB_UPDATE_STARTER_CODE_QUEUE
      JOB_UPDATE_STARTER_CODE_QUEUE
    else
      'jobs'
    end
  end

end
