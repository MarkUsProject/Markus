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
  DEBUG = 1
  # INFO:  generic (useful) information about system operation
  INFO = 2
  # WARN:  a warning
  WARN = 3
  # ERROR: a handleable error condition
  ERROR = 4
  # FATAL: an unhandleable error that results in a program crash
  FATAL = 5 

  #===Description
  # The singleton module makes the new method private.
  # To initialize a new MarkusLogger object it is necessary to call
  # instance instead of new. 
  # The variables that the loggers will use are defined in the
  # environment.rb file
  #===Exceptions
  # If the variables MARKUS_LOGGING_ROTATE_INTERVAL, MARKUS_LOGGING_ERRORLOGFILE, MARKUS_LOGGING_LOGFILE
  # or MARKUS_LOGGING_SIZE_THRESHOLD are not valid an exception of type MarkusLoggerConfigurationError
  # is raised
  def initialize
    rotate_by_time = MARKUS_LOGGING_ROTATE_BY_INTERVAL
    size = MARKUS_LOGGING_SIZE_THRESHOLD
    error_log_file = MARKUS_LOGGING_ERRORLOGFILE
    log_file = MARKUS_LOGGING_LOGFILE
    interval = MARKUS_LOGGING_ROTATE_INTERVAL
    old_files = MARKUS_LOGGING_OLDFILES
    if !(valid_file?(error_log_file) && valid_file?(log_file))
      raise MarkusLoggerConfigurationError.new('The log files are not valid')
    end
    if rotate_by_time
      if !['daily', 'weekly', 'monthly'].include?(interval)
        raise MarkusLoggerConfigurationError.new('The rotation interval is not valid')
      end
      @__logger__ = Logger.new(log_file, interval)
      @__logger__.formatter = Logger::Formatter.new
      @__errorLogger__ = Logger.new(error_log_file, interval)
      @__errorLogger__.formatter = Logger::Formatter.new
    else
      if size > 0
        if old_files <= 0
          raise MarkusLoggerConfigurationError.new('The number of old logfiles to keep has to be bigger than 0')
        end
        @__logger__ = Logger.new(log_file, old_files, size)
        @__logger__.formatter = Logger::Formatter.new
        @__errorLogger__ = Logger.new(error_log_file, old_files, size)
        @__errorLogger__.formatter = Logger::Formatter.new
      else
        raise MarkusLoggerConfigurationError.new('The threshold size for the logger has to be bigger than 0')
      end
    end
  end


#=== Description
#Logs a message with the given log level severity. The default log level value is INFO.
#Any message that can be turned to a string will be logged, else the output of the inspect
#method will be logged.
#=== Return
#true if successful, false otherwise.
#=== Exceptions
#When the log level is not known then an exception of type ArgumentError is raised
  def log(msg, level=INFO)
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
      raise ArgumentError,('Logger: Unknown loglevel')
    end
  end

#=== Description
#Checks if the filename is valid
#=== Return
#true if the file exists and it is writable or if the file doesn't exist and  the
#directory of the file is writable and it exists, false otherwise.
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
