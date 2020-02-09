# Simple logging utility for MarkUs

# This class is responsible to initialize the loggers
# used by MarkUs and redirect the messages to the correct
# logger

require 'singleton'
require 'logger'

class MarkusLogger

  # This class must use the singleton pattern since
  # we only want one instance of this class through the whole
  # program.
  include Singleton

  # DEBUG: low-level information for developers
  if !defined?(DEBUG)
    DEBUG = 1
  end
  # INFO:  generic (useful) information about system operation
  if !defined?(INFO)
    INFO = 2
  end
  # WARN:  a warning
  if !defined?(WARN)
    WARN = 3
  end
  # ERROR: a handleable error condition
  if !defined?(ERROR)
    ERROR = 4
  end
  # FATAL: an unhandleable error that results in a program crash
  if !defined?(FATAL)
    FATAL = 5
  end

  #===Description
  # The singleton module makes the new method private.
  # To initialize a new MarkusLogger object it is necessary to call
  # instance instead of new.
  # The variables that the loggers will use are defined in the
  # environment.rb file
  #===Exceptions
  # If the configuration variables configuration.x.logging.rotate_interval,
  # config.x.logging.error_file, configuration.x.logging.log_file
  # or configuration.x.logging.size_threshold are not valid an exception of type
  # MarkusLoggerConfigurationError is raised.
  def initialize
    my_pid = Process.pid
    size = Rails.configuration.x.logging.size_threshold
    error_log_file = "#{Rails.configuration.x.logging.error_file}.#{my_pid}"
    log_file = "#{Rails.configuration.x.logging.log_file}.#{my_pid}"
    interval = Rails.configuration.x.logging.rotate_interval
    old_files = Rails.configuration.x.logging.old_files
    if !(valid_file?(error_log_file) && valid_file?(log_file))
      raise MarkusLoggerConfigurationError.new('The log files are not valid')
    end
    if Rails.configuration.x.logging.rotate_by_interval
      if !['daily', 'weekly', 'monthly'].include?(interval)
        raise MarkusLoggerConfigurationError.new('The rotation interval is not valid')
      end
      @__logger__ = Logger.new(log_file, interval)
      @__logger__.formatter = Logger::Formatter.new
      @__logger__.datetime_format = "%Y-%m-%d %H:%M:%S  "
      @__errorLogger__ = Logger.new(error_log_file, interval)
      @__errorLogger__.formatter = Logger::Formatter.new
      @__errorLogger__.datetime_format = "%Y-%m-%d %H:%M:%S  "
    else
      if size > 0
        if old_files <= 0
          raise MarkusLoggerConfigurationError.new('The number of old logfiles to keep has to be bigger than 0')
        end
        @__logger__ = Logger.new(log_file, old_files, size)
        @__logger__.formatter = Logger::Formatter.new
        @__logger__.datetime_format = "%Y-%m-%d %H:%M:%S  "
        @__errorLogger__ = Logger.new(error_log_file, old_files, size)
        @__errorLogger__.formatter = Logger::Formatter.new
        @__errorLogger__.datetime_format = "%Y-%m-%d %H:%M:%S  "
      else
        raise MarkusLoggerConfigurationError.new('The threshold size for the logger has to be bigger than 0')
      end
    end
  end


  #=== Description
  # Logs a message with the given log level severity. The default log level value is INFO.
  # Any message that can be turned to a string will be logged, else the output of the inspect
  # method will be logged.
  #=== Return
  # true if successful, false otherwise.
  #=== Exceptions
  # When the log level is not known then an exception of type ArgumentError is raised
  def log(msg, level=INFO)
    return unless Rails.configuration.x.logging.enabled

    case level
    when INFO
      @__logger__.info(msg)
    when DEBUG
      @__logger__.debug(msg)
    when WARN
      @__logger__.warn(msg)
    when ERROR
      @__errorLogger__.error(msg)
    when FATAL
      @__errorLogger__.fatal(msg)
    else
      raise ArgumentError, 'Logger: Unknown loglevel'
    end
  end

  #=== Description
  # Checks if the filename is valid
  #=== Return
  # true if the file exists and it is writable or if the file doesn't exist and  the
  # directory of the file is writable and it exists, false otherwise.
  def valid_file?(f)
    dir = File.dirname(f)
    if(File.file?(f) && File.writable?(f))
      return true
    elsif (File.exist?(dir) && File.writable?(dir) && !File.directory?(f) && !File.file?(f) )
      return true
    else
      return false
    end
  end

  private :valid_file?

end

# Exception type called by MarkusLogger
class MarkusLoggerConfigurationError < Exception
end
