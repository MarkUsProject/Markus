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
  def self.check_config
    check_in_readable_dir(MarkusConfigurator.markus_config_logging_logfile, 'MARKUS_LOGGING_LOGFILE')
    check_in_writable_dir(MarkusConfigurator.markus_config_logging_logfile, 'MARKUS_LOGGING_LOGFILE')
    check_in_executable_dir(MarkusConfigurator.markus_config_logging_logfile, 'MARKUS_LOGGING_LOGFILE')
    check_in_readable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, 'MARKUS_LOGGING_ERRORLOGFILE')
    check_in_writable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, 'MARKUS_LOGGING_ERRORLOGFILE')
    check_in_executable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, 'MARKUS_LOGGING_ERRORLOGFILE')
    check_writable(MarkusConfigurator.markus_config_repository_storage, 'REPOSITORY_STORAGE')
    check_readable(MarkusConfigurator.markus_config_repository_storage, 'REPOSITORY_STORAGE')
    check_executable(MarkusConfigurator.markus_config_repository_storage, 'REPOSITORY_STORAGE')
    check_in_writable_dir(MarkusConfigurator.markus_ate_client_dir, 'automated_tests_REPOSITORY')
    check_configured_default_language(MarkusConfigurator.markus_config_default_language)
    ensure_logout_redirect_link_valid
    unless RUBY_PLATFORM =~ /(:?mswin|mingw)/  # should match for Windows only
      check_if_executes(MarkusConfigurator.markus_config_validate_file, 'VALIDATE_FILE')
    end
  end

  # Checks if language file for configured default
  # language is present.
  def self.check_configured_default_language(lang)
    available_languages = Dir.glob(File.join( ::Rails.root.to_s, 'config', 'locales', '*.yml' ))
    available_languages = available_languages.collect{ |file| File.basename(file).chomp('.yml') }
    unless available_languages.include?(lang)
      raise ("Language file #{lang}.yml does not exist in config/locales. Please " +
          'make sure that MARKUS_DEFAULT_LANGUAGE is configured correctly in ' +
          "config/environments/#{Rails.env}.rb and language file is present.")
    end
  end

  # checks if the given file's directory is writable
  # and raises an exception if it is not
  def self.check_in_writable_dir(filename, constant_name)
    dir = Pathname.new(filename).dirname
    unless File.writable?(dir)
      raise ("The setting #{constant_name} with path #{dir} is not writable. Please double" +
          " check the setting in config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file's directory is readable
  # and raises an exception if it is not
  def self.check_in_readable_dir(filename, constant_name)
    dir = Pathname.new(filename).dirname
    unless File.readable?(dir)
      raise ("The setting #{constant_name} with path #{dir} is not readable. Please double" +
          " check the setting in config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file's directory is executable
  # and raises an exception if it is not
  def self.check_in_executable_dir(filename, constant_name)
    dir = Pathname.new(filename).dirname
    if ! File.executable?(dir)
      raise ("The setting #{constant_name} with path #{dir} is not executable. Please double " +
          "check the setting in config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file is writable and raises
  # an exception if it is not
  def self.check_writable(filename, constant_name)
    unless File.writable?(filename)
      raise ("The setting #{constant_name} with path #{filename} is not writable. Please double" +
          " check the setting in config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file is readable and raises
  # an exception if it is not
  def self.check_readable(filename, constant_name)
    unless File.readable?(filename)
      raise ("The setting #{constant_name} with path #{filename} is not readable. Please double" +
          " check the setting in config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file is executable and raises
  # an exception if it is not.
  def self.check_executable(filename, constant_name)
    unless File.executable?(filename)
      raise ("The setting #{constant_name} with path #{filename} is not executable. Please double " +
          "check the setting in config/environments/#{Rails.env}.rb")
    end
  end

  # checks if the given file executes succesfully
  def self.check_if_executes(filename, constant_name)
    output = ''
    executable = (File.exist?(filename)) ? File.stat(filename).executable? : false

    if executable
      IO.popen("\"#{filename}\"", 'r+') do |pipe|
        pipe.puts("test\ntest")
        pipe.close_write

        output = pipe.read
        pipe.close_read
      end
    end

    unless executable && output.length == 0
      if !executable || output =~ /(Errno::ENOENT)|(Permission denied)/
        raise ("The setting #{constant_name} with path #{filename} is not executable. Please double " +
               "check the setting in config/environments/#{Rails.env}.rb" )
      else
        # This may not indicate an error. Log this, but do no more.
        $stderr.puts "Output received for #{filename}: #{output}. Please double check the" +
                     " setting in config/environments/#{Rails.env}.rb"
      end
    end
  end

  def self.ensure_logout_redirect_link_valid
    logout_redirect = MarkusConfigurator.markus_config_logout_redirect
    if %w(DEFAULT NONE).include?(logout_redirect)
      return
    #We got a URI, ensure its of proper format <>
    elsif logout_redirect.match('^http://|^https://').nil?
      raise ( "LOGOUT_REDIRECT value #{logout_redirect} is invalid. Only 'DEFAULT', " +
              "'NONE' or addresses beginning with http:// or https:// are valid values. " +
              "Please double check configuration in config/environments/#{Rails.env}.rb" )
    end
  end

end
