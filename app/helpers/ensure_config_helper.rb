module EnsureConfigHelper
  
=begin
- repository directory exists
  - is writable/readable
- VALIDATE_FILE
  - is executable
- logging
  - MARKUS_LOGGING_LOGFILE's parent dir is writable
  - MARKUS_LOGGING_ERRORLOGFILE's parent dir is writable
=end
  # check directory instead of file because, the logger has not created
  # the file yet
  def self.check_config()
    check_in_readable_dir(MarkusConfigurator.markus_config_logging_logfile, "MARKUS_LOGGING_LOGFILE")
    check_in_writable_dir(MarkusConfigurator.markus_config_logging_logfile, "MARKUS_LOGGING_LOGFILE")
    check_in_executable_dir(MarkusConfigurator.markus_config_logging_logfile, "MARKUS_LOGGING_LOGFILE")
    check_in_readable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, "MARKUS_LOGGING_ERRORLOGFILE")
    check_in_writable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, "MARKUS_LOGGING_ERRORLOGFILE")
    check_in_executable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, "MARKUS_LOGGING_ERRORLOGFILE")
    check_writable(MarkusConfigurator.markus_config_repository_storage, "REPOSITORY_STORAGE")
    check_readable(MarkusConfigurator.markus_config_repository_storage, "REPOSITORY_STORAGE")
    check_executable(MarkusConfigurator.markus_config_repository_storage, "REPOSITORY_STORAGE")
    if ! ( RUBY_PLATFORM =~ /(:?mswin|mingw)/ ) # should match for Windows only
      check_if_executes( MarkusConfigurator.markus_config_validate_file, "VALIDATE_FILE")
    end
  end
  
  # checks if the given file's directory is writable 
  # and raises an exception if it is not
  def self.check_in_writable_dir( filename, constant_name )
    dir = Pathname.new( filename ).dirname
    if ! File.writable?(dir)
      raise I18n.t("ensure_config.path_not_writable", :constant_name => constant_name, :file_name => dir, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end
  
  # checks if the given file's directory is readable 
  # and raises an exception if it is not
  def self.check_in_readable_dir( filename, constant_name )
    dir = Pathname.new( filename ).dirname
    if ! File.readable?( dir )
      raise I18n.t("ensure_config.path_not_readable", :constant_name => constant_name, :file_name => dir, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end
  
  # checks if the given file's directory is executable
  # and raises an exception if it is not
  def self.check_in_executable_dir( filename, constant_name )
    dir = Pathname.new( filename ).dirname
    if ! File.executable?( dir )
      raise I18n.t("ensure_config.path_not_executable", :constant_name => constant_name, :file_name => dir, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file is writable and raises
  # an exception if it is not
  def self.check_writable( filename, constant_name )
    if ! File.writable?(filename)
      raise I18n.t("ensure_config.path_not_writable", :constant_name => constant_name, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end
  
  # checks if the given file is readable and raises
  # an exception if it is not
  def self.check_readable( filename, constant_name )
    if ! File.readable?(filename)
      raise I18n.t("ensure_config.path_not_readable", :constant_name => constant_name, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end
  
  # checks if the given file is executable and raises
  # an exception if it is not.
  def self.check_executable( filename, constant_name )
    if ! File.executable?(filename)
      raise I18n.t("ensure_config.path_not_executable", :constant_name => constant_name, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end
  
  # checks if the given file executes succesfully
  def self.check_if_executes( filename, constant_name )
    begin
      p = IO.popen( filename, "w+" )
      p.puts("test\ntest") # write to stdin of markus_config_validate
      p.close
      error_code = $?
      if error_code != 0 and error_code !=1 and error_code != 2
        raise I18n.t("ensure_config.file_does_not_execute", :constant_name => constant_name, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
      end
    rescue Errno::EPIPE
      raise I18n.t("ensure_config.file_does_not_execute", :constant_name => constant_name, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end

end
