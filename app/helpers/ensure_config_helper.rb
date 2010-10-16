require 'open3' # required for popen3

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
    check_writable(MarkusConfigurator.markus_config_pdf_storage, "PDF_STORAGE")
    check_readable(MarkusConfigurator.markus_config_pdf_storage, "PDF_STORAGE")
    check_in_writable_dir(MarkusConfigurator.markus_config_test_framework_repository, "TEST_FRAMEWORK_REPOSITORY")
    ensure_logout_redirect_link_valid
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
    p_stdin, p_stdout, p_stderr = Open3.popen3( filename )
    p_stdin.puts("test\ntest") # write to stdin of markus_config_validate
    p_stdin.close
    # HACKALARM:
    # Disconnect from DB before reading from stderr. PostgreSQL gets confused
    # if we don't do this. Since these checks run on server startup/shutdown
    # only, this should be OK.
    con_identifier = ActiveRecord::Base.remove_connection
    error = p_stderr.read
    # Get DB connection back
    ActiveRecord::Base.establish_connection(con_identifier)
    if error.length != 0
      if error =~ /(Errno::ENOENT)|(Permission denied)/
        raise I18n.t("ensure_config.file_does_not_execute", :constant_name => constant_name, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
      else
        # This may not indicate an error (maybe just authentication failed and something
        # was printed to stderr). Log this, but do no more.
        $stderr.puts I18n.t("ensure_config.error_writing_to_pipe", :error => error, :file_name => filename, :config_location => "config/environments/#{Rails.env}.rb")
      end
    end
  end

  def self.ensure_logout_redirect_link_valid
    logout_redirect = MarkusConfigurator.markus_config_logout_redirect
    if ["DEFAULT", "NONE"].include?(logout_redirect)
      return
    #We got a URI, ensure its of proper format <>
    elsif logout_redirect.match('^http://|^https://').nil?
      raise I18n.t("ensure_config.invalid_logout_redirect", :path => logout_redirect, :config_location => "config/environments/#{Rails.env}.rb")
    end
  end

end
