# ActiveRecord::Base mixin to configure MarkUs
# All descendants have the following methods available

module MarkusConfigurator
  
  ######################################
  # Repository configuration
  ######################################
  def markus_config_repository_admin?
    return (IS_REPOSITORY_ADMIN == true)
  end
  
  def markus_config_repository_storage
    return REPOSITORY_STORAGE || File.join(RAILS_ROOT, "repositories")
  end
  
  def markus_config_repository_type
    return REPOSITORY_TYPE || "svn"
  end
  
  def markus_config_repository_external_base_url
    return REPOSITORY_EXTERNAL_BASE_URL || "http://www.example.com/svn"
  end
  
  def markus_config_repository_external_submits_only?
    if repository_admin? && (REPOSITORY_EXTERNAL_SUBMITS_ONLY || false)
      case repository_type
        when "svn"
          retval = true
        else
          retval = false
      end
    else
      retval = false
    end
    return retval
  end
  
  def markus_config_repository_permission_file
    return REPOSITORY_PERMISSION_FILE || File.join(repository_storage, "svn_authz")
  end
  
  def markus_config_external_submits_only?
    return REPOSITORY_EXTERNAL_SUBMITS_ONLY || false
  end
  
  ######################################
  # MarkusLogger configuration
  ######################################
  def markus_config_logging_rotate_by_interval
    return MARKUS_LOGGING_ROTATE_BY_INTERVAL || false
  end
  
  def markus_config_logging_size_threshold
    return MARKUS_LOGGING_SIZE_THRESHOLD || (1024 * 10**6)
  end
  
  def markus_config_logging_rotate_interval
    return MARKUS_LOGGING_ROTATE_INTERVAL || 'daily'
  end
  
  def markus_config_logging_logfile
    return MARKUS_LOGGING_LOGFILE || File.join(RAILS_ROOT, "log", "#{RAILS_ENV}_info.log")
  end
  
  def markus_config_logging_errorlogfile
    return MARKUS_LOGGING_ERRORLOGFILE || File.join(RAILS_ROOT, "log", "#{RAILS_ENV}_error.log")
  end
  
  def markus_config_logging_num_oldfiles
    return MARKUS_LOGGING_OLDFILES || 10
  end

end