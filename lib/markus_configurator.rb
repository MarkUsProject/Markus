# ActiveRecord::Base mixin to configure MarkUs
# All descendants have the following methods available

module MarkusConfigurator

  class NotDefined < RuntimeError
    attr_reader :parameter
    def initialize(parameter)
      super "'#{parameter}' is not defined for #{::Rails.env} environment.
             Take a look at #{::Rails.root.to_s}/config/config.yml"
    end
  end

  ######################################
  # Repository configuration
  ######################################
  def markus_config_repository_admin?
    if MARKUS_CONFIG['is_repository_admin'].nil?
      raise NotDefined.new('is_repository_admin')
    else
      MARKUS_CONFIG['is_repository_admin']
    end
  end

  def markus_config_repository_storage
    if MARKUS_CONFIG['repository_storage'].nil?
      raise NotDefined.new('repository_storage')
    else
      MARKUS_CONFIG['repository_storage']
    end
  end

  def markus_config_pdf_storage
    if MARKUS_CONFIG['pdf_storage'].nil?
      raise NotDefined.new('pdf_storage')
    else
      MARKUS_CONFIG['pdf_storage']
    end
  end

  def markus_config_pdf_support
    if MARKUS_CONFIG['pdf_support'].nil?
      raise NotDefined.new('pdf_support')
    else
      MARKUS_CONFIG['pdf_support']
    end
  end

  def markus_config_repository_type
    if MARKUS_CONFIG['repository_type'].nil?
      raise NotDefined.new('repository_type')
    else
      MARKUS_CONFIG['repository_type']
    end
  end

  def markus_config_repository_external_base_url
    if MARKUS_CONFIG['repository_external_base_url'].nil?
      raise NotDefined.new('repository_external_base_url')
    else
      MARKUS_CONFIG['repository_external_base_url']
    end
  end

  def markus_config_repository_external_submits_only?
    if MARKUS_CONFIG['repository_external_submits_only'].nil?
      raise NotDefined.new('repository_external_submits_only')
    else
      case markus_config_repository_type
        when 'svn'
          MARKUS_CONFIG['repository_external_submits_only']
        else
          false
      end
    end

  end

  def markus_config_repository_permission_file
    if MARKUS_CONFIG['repository_permission_file'].nil?
      raise NotDefined.new('repository_permission_file')
    else
      MARKUS_CONFIG['repository_permission_file']
    end
  end

  def markus_config_course_name
    if MARKUS_CONFIG['course_name'].nil?
      raise NotDefined.new('course_name')
    else
      MARKUS_CONFIG['course_name']
    end
  end

  def markus_config_logout_redirect
    if MARKUS_CONFIG['logout_redirect'].nil?
      raise NotDefined.new('logout_redirect')
    else
      MARKUS_CONFIG['logout_redirect']
    end
  end

  def markus_config_remote_user_auth
    if MARKUS_CONFIG['remote_user_auth'].nil?
      raise NotDefined.new('remote_user_auth')
    else
      MARKUS_CONFIG['remote_user_auth']
    end
  end

  #Repository for the test framework
  #Students file will be compiled, executed and tested in this repository
  def markus_config_automated_tests_repository
    if MARKUS_CONFIG['automated_tests_repository'].nil?
      raise NotDefined.new('automated_tests_repository')
    else
      MARKUS_CONFIG['automated_tests_repository']
    end
  end

  ###########################################
  # Markus Session cookie configuration
  ###########################################
  def markus_config_session_cookie_name
    if MARKUS_CONFIG['session_cookie_name'].nil?
      raise NotDefined.new('session_cookie_name')
    else
      MARKUS_CONFIG['session_cookie_name']
    end
  end

  def markus_config_session_cookie_secret
    if MARKUS_CONFIG['session_cookie_secret'].nil?
      raise NotDefined.new('session_cookie_secret')
    else
      MARKUS_CONFIG['session_cookie_secret']
    end
  end

  def markus_config_session_cookie_expire_after
    if MARKUS_CONFIG['session_cookie_expire_after'].nil?
      raise NotDefined.new('session_cookie_expire_after')
    else
      MARKUS_CONFIG['session_cookie_expire_after']
    end
  end

  def markus_config_session_cookie_http_only
    if MARKUS_CONFIG['session_cookie_http_only'].nil?
      raise NotDefined.new('session_cookie_http_only')
    else
      MARKUS_CONFIG['session_cookie_http_only']
    end
  end

  def markus_config_session_cookie_secure
    if MARKUS_CONFIG['session_cookie_secure'].nil?
      raise NotDefined.new('session_cookie_secure')
    else
      MARKUS_CONFIG['session_cookie_secure']
    end
  end
  ######################################
  # MarkusLogger configuration
  ######################################
  def markus_config_logging_enabled?
    if MARKUS_CONFIG['markus_logging_enabled'].nil?
      raise NotDefined.new('markus_logging_enabled')
    else
      MARKUS_CONFIG['markus_logging_enabled']
    end
  end

  def markus_config_logging_rotate_by_interval
    if MARKUS_CONFIG['markus_logging_rotate_by_interval'].nil?
      raise NotDefined.new('markus_logging_rotate_by_interval')
    else
      MARKUS_CONFIG['markus_logging_rotate_by_interval']
    end
  end

  def markus_config_logging_size_threshold
    if MARKUS_CONFIG['markus_logging_size_threshold'].nil?
      raise NotDefined.new('markus_logging_size_threshold')
    else
      MARKUS_CONFIG['markus_logging_size_threshold']
    end
  end

  def markus_config_logging_rotate_interval
    if MARKUS_CONFIG['markus_logging_rotate_interval'].nil?
      raise NotDefined.new('markus_logging_rotate_interval')
    else
      MARKUS_CONFIG['markus_logging_rotate_interval']
    end
  end

  def markus_config_logging_logfile
    if MARKUS_CONFIG['markus_logging_logfile'].nil?
      raise NotDefined.new('markus_logging_logfile')
    else
      MARKUS_CONFIG['markus_logging_logfile']
    end
  end

  def markus_config_logging_errorlogfile
    if MARKUS_CONFIG['markus_logging_errorlogfile'].nil?
      raise NotDefined.new('markus_logging_errorlogfile')
    else
      MARKUS_CONFIG['markus_logging_errorlogfile']
    end
  end

  def markus_config_logging_num_oldfiles
    if MARKUS_CONFIG['markus_logging_oldfiles'].nil?
      raise NotDefined.new('markus_logging_oldfiles')
    else
      MARKUS_CONFIG['markus_logging_oldfiles']
    end
  end

  def markus_config_default_language
    if MARKUS_CONFIG['markus_default_language'].nil?
      raise NotDefined.new('markus_default_language')
    else
      MARKUS_CONFIG['markus_default_language']
    end
  end

  def markus_config_validate_file
    if MARKUS_CONFIG['validate_file'].nil?
      raise NotDefined.new('validate_file')
    else
      MARKUS_CONFIG['validate_file']
    end
  end

  def markus_config_user_student_session_timeout
    if MARKUS_CONFIG['user_student_session_timeout'].nil?
      raise NotDefined.new('user_student_session_timeout')
    else
      MARKUS_CONFIG['user_student_session_timeout']
    end
  end

  def markus_config_user_ta_session_timeout
    if MARKUS_CONFIG['user_ta_session_timeout'].nil?
      raise NotDefined.new('user_ta_session_timeout')
    else
      MARKUS_CONFIG['user_ta_session_timeout']
    end
  end

  def markus_config_user_admin_session_timeout
    if MARKUS_CONFIG['user_admin_session_timeout'].nil?
      raise NotDefined.new('user_admin_session_timeout')
    else
      MARKUS_CONFIG['user_admin_session_timeout']
    end
  end

  def markus_config_user_student_csv_upload_order
    if MARKUS_CONFIG['user_student_csv_upload_order'].nil?
      raise NotDefined.new('user_student_csv_upload_order')
    else
      MARKUS_CONFIG['user_student_csv_upload_order']
    end
  end

  def markus_config_user_ta_csv_upload_order
    if MARKUS_CONFIG['user_ta_csv_upload_order'].nil?
      raise NotDefined.new('user_ta_csv_upload_order')
    else
      MARKUS_CONFIG['user_ta_csv_upload_order']
    end
  end

end