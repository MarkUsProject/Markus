namespace :markus do
  desc 'Verify the configuration of a MarkUs installation.'
  task check: :environment do
    check_config
  end

  def check_config
    check_in_readable_dir(MarkusConfigurator.markus_config_logging_logfile, 'MARKUS_LOGGING_LOGFILE')
    check_in_writable_dir(MarkusConfigurator.markus_config_logging_logfile, 'MARKUS_LOGGING_LOGFILE')
    check_in_executable_dir(MarkusConfigurator.markus_config_logging_logfile, 'MARKUS_LOGGING_LOGFILE')
    check_in_readable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, 'MARKUS_LOGGING_ERRORLOGFILE')
    check_in_writable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, 'MARKUS_LOGGING_ERRORLOGFILE')
    check_in_executable_dir(MarkusConfigurator.markus_config_logging_errorlogfile, 'MARKUS_LOGGING_ERRORLOGFILE')
    check_writable(Rails.configuration.x.repository.storage, 'REPOSITORY_STORAGE')
    check_readable(Rails.configuration.x.repository.storage, 'REPOSITORY_STORAGE')
    check_executable(Rails.configuration.x.repository.storage, 'REPOSITORY_STORAGE')
    check_in_writable_dir(MarkusConfigurator.autotest_client_dir, 'autotest_REPOSITORY')
    ensure_logout_redirect_link_valid
  end

  # Checks whether the given file's directory is writable.
  def self.check_in_writable_dir(filename, constant_name)
    dir = Pathname.new(filename).dirname
    unless File.writable?(dir)
      raise MarkUsConfigError("The setting #{constant_name} with path #{dir} is not writable.")
    end
  end

  # Checks whether the given file's directory is readable.
  def check_in_readable_dir(filename, constant_name)
    dir = Pathname.new(filename).dirname
    unless File.readable?(dir)
      raise MarkUsConfigError("The setting #{constant_name} with path #{dir} is not readable.")
    end
  end

  # Checks whether the given file's directory is executable.
  def check_in_executable_dir(filename, constant_name)
    dir = Pathname.new(filename).dirname
    unless File.executable?(dir)
      raise MarkUsConfigError("The setting #{constant_name} with path #{dir} is not executable.")
    end
  end

  # Checks whether the given file is writable.
  def check_writable(filename, constant_name)
    unless File.writable?(filename)
      raise MarkUsConfigError("The setting #{constant_name} with path #{filename} is not writable.")
    end
  end

  # Checks whether the given file is readable.
  def self.check_readable(filename, constant_name)
    unless File.readable?(filename)
      raise MarkUsConfigError("The setting #{constant_name} with path #{filename} is not readable.")
    end
  end

  # Checks whether the given file is executable.
  def check_executable(filename, constant_name)
    unless File.executable?(filename)
      raise MarkUsConfigError("The setting #{constant_name} with path #{filename} is not executable.")
    end
  end

  def ensure_logout_redirect_link_valid
    logout_redirect = MarkusConfigurator.markus_config_logout_redirect
    if %w[DEFAULT NONE].include?(logout_redirect)
      return
      # We got a URI, ensure its of proper format <>
    elsif logout_redirect.match('^http://|^https://').nil?
      raise "LOGOUT_REDIRECT value #{logout_redirect} is invalid. Only 'DEFAULT', "\
          "'NONE' or addresses beginning with http:// or https:// are valid values. "\
          "Please double check configuration in config/environments/#{Rails.env}.rb"
    end
  end

  class MarkUsConfigError < StandardError
  end
end
