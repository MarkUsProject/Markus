# Settings specified here will take precedence over those in config/environment.rb
Markus::Application.configure do
  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_view.debug_rjs                         = true
  config.action_controller.perform_caching             = false
  config.action_controller.allow_forgery_protection    = true

  # Load any local configuration that is kept out of source control
  if File.exists?(File.join(File.dirname(__FILE__), 'local_environment_override.rb'))
    instance_eval File.read(File.join(File.dirname(__FILE__), 'local_environment_override.rb'))
  end

  # Show Deprecated Warnings (to :log or to :stderr)
  config.active_support.deprecation = :stderr

  config.log_level = :debug
  # set log-level (:debug, :info, :warn, :error, :fatal)

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  require 'ruby-debug'

  ###################################################################
  # MarkUs SPECIFIC CONFIGURATION
  #   - use "/" as path separator no matter what OS server is running
  ###################################################################

  ###################################################################
  # Set the course name here
  COURSE_NAME         = "CSC108 Fall 2009: Introduction to Computer Programming"

  ###################################################################
  # MarkUs relies on external user authentication: An external script
  # (ideally a small C program) is called with username and password
  # piped to stdin of that program (first line is username, second line
  # is password).
  #
  # If and only if it exits with a return code of 0, the username/password
  # combination is considered valid and the user is authenticated. Moreover,
  # the user is authorized, if it exists as a user in MarkUs.
  #
  # That is why MarkUs does not allow usernames/passwords which contain
  # \n or \0. These are the only restrictions.
  VALIDATE_FILE = "#{::Rails.root.to_s}/config/dummy_validate.sh"

  ###################################################################
  # Authentication Settings
  ###################################################################
  # Set this to true/false if you want to use an external authentication scheme
  # that sets the REMOTE_USER variable.

  REMOTE_USER_AUTH = false

  ###################################################################
  # This is where the logout button will redirect to when clicked.
  # Set this to one of the three following options:
  #
  # "DEFAULT" - MarkUs will use its default logout routine.
  # A logout link will be provided.
  #
  # The DEFAULT option should not be used if REMOTE_USER_AUTH is set to true,
  # as it will not result in a successful logout.
  #
  # -----------------------------------------------------------------------------
  #
  # "http://address.of.choice" - Logout will redirect to the specified URI.
  #
  # If REMOTE_USER_AUTH is set to true, it would be possible
  # to specify a custom address which would log the user out of the authentication
  # scheme.
  # Choosing this option with REMOTE_USER_AUTH is set to false will still properly
  # log the user out of MarkUs.
  #
  # -----------------------------------------------------------------------------
  #
  # "NONE" - Logout link will be hidden.
  #
  # It only recommended that you use this if REMOTE_USER_AUTH is set to true
  # and do not have a custom logout page.
  #
  # If you are using HTTP's basic authentication, you probably want to use this
  # option.

  LOGOUT_REDIRECT = "DEFAULT"

  ###################################################################
  # File storage (Repository) settings
  ###################################################################
  # Options for Repository_type are 'svn' and 'memory' for now
  # 'memory' is by design not persistent and only used for testing MarkUs
  REPOSITORY_TYPE = "svn" # use Subversion as storage backend

  ###################################################################
  # Directory where Repositories will be created. Make sure MarkUs is allowed
  # to write to this directory
  REPOSITORY_STORAGE = "#{::Rails.root.to_s}/data/dev/repos"

  ###################################################################
  # Directory where converted PDF files will be stored as JPEGs. Make sure MarkUs
  # is allowed to write to this directory

  PDF_STORAGE = "#{::Rails.root.to_s}/data/dev/pdfs"

  ###################################################################
  # Directory where the Automated Testing Repositories will be created.
  # make sure markus is allowed to write to this directory
  AUTOMATED_TESTS_REPOSITORY = "#{::Rails.root.to_s}/data/dev/automated_tests"

  ###################################################################
  # Set this to true or false if you want to be able to display and annotate
  # PDF documents within the browser.
  # When collecting pdfs files, it converts them to jpg format via RGhost.
  # RGhost is ghostscript dependent. Be sure ghostscript is installed.
  PDF_SUPPORT = false 

  ###################################################################
  # Change this to 'REPOSITORY_EXTERNAL_SUBMITS_ONLY = true' if you
  # are using Subversion as a storage backend and the instructor wants his/her
  # students to submit to the repositories Subversion clients only. Set this
  # to true if you intend to force students to submit via Subversion
  # clients only. The MarkUs Web interface for submissions will be read-only.
  REPOSITORY_EXTERNAL_SUBMITS_ONLY = false

  ###################################################################
  # This config setting only makes sense, if you are using
  # 'REPOSITORY_EXTERNAL_SUBMITS_ONLY = true'. If you have Apache httpd
  # configured so that the repositories created by MarkUs will be available to
  # the outside world, this is the URL which internally "points" to the
  # REPOSITORY_STORAGE directory configured earlier. Hence, Subversion
  # repositories will be available to students for example via URL
  # http://www.example.com/markus/svn/Repository_Name. Make sure the path
  # after the hostname matches your <Location> directive in your Apache
  # httpd configuration
  REPOSITORY_EXTERNAL_BASE_URL = "http://www.example.com/markus/svn"

  ###################################################################
  # This setting is important for two scenarios:
  # First, if MarkUs should use Subversion repositories created by a
  # third party, point it to the place where it will find the Subversion
  # authz file. In that case, MarkUs would need at least read access to
  # that file.
  # Second, if MarkUs is configured with REPOSITORY_EXTERNAL_SUBMITS_ONLY
  # set to 'true', you can configure as to where MarkUs should write the
  # Subversion authz file.
  REPOSITORY_PERMISSION_FILE = REPOSITORY_STORAGE + "/svn_authz"

  ###################################################################
  # This setting configures if MarkUs is reading Subversion
  # repositories' permissions only OR is admin of the Subversion
  # repositories. In the latter case, it will write to
  # $REPOSITORY_SVN_AUTHZ_FILE, otherwise it doesn't. Change this to
  # 'false' if repositories are created by a third party.
  IS_REPOSITORY_ADMIN = true

  ###################################################################
  # Set this to the desired default language MarkUs should load if
  # nothing else tells it otherwise. At the moment valid values are
  # 'en', 'fr'. Please make sure that proper locale files are present
  # in config/locales.
  MARKUS_DEFAULT_LANGUAGE = 'en'

  ###################################################################
  # Session Timeouts
  ###################################################################
  USER_STUDENT_SESSION_TIMEOUT        = 1800 # Timeout for student users
  USER_TA_SESSION_TIMEOUT             = 1800 # Timeout for grader users
  USER_ADMIN_SESSION_TIMEOUT          = 1800 # Timeout for admin users

  ###################################################################
  # CSV upload order of fields (usually you don't want to change this)
  ###################################################################
  # Order of student CSV uploads
  USER_STUDENT_CSV_UPLOAD_ORDER = [:user_name, :last_name, :first_name, :section_name]
  # Order of graders CSV uploads
  USER_TA_CSV_UPLOAD_ORDER  = [:user_name, :last_name, :first_name]

  ###################################################################
  # Logging Options
  ###################################################################
  # If set to true then the rotation of the logfiles will be defined
  # by MARKUS_LOGGING_ROTATE_INTERVAL instead of the size of the file
  MARKUS_LOGGING_ROTATE_BY_INTERVAL = false
  # Set the maximum size file that the logfiles will have before rotating
  MARKUS_LOGGING_SIZE_THRESHOLD = 1024000000
  # Sets the interval which rotations will occur if
  # MARKUS_LOGGING_ROTATE_BY_INTERVAL is set to true,
  # possible values are: 'daily', 'weekly', 'monthly'
  MARKUS_LOGGING_ROTATE_INTERVAL = 'daily'
  # Name of the logfile that will carry information, debugging and
  # warning messages
  MARKUS_LOGGING_LOGFILE = "log/info_#{::Rails.env}.log"
  # Name of the logfile that will carry error and fatal messages
  MARKUS_LOGGING_ERRORLOGFILE = "log/error_#{::Rails.env}.log"
  # This variable sets the number of old log files that will be kept
  MARKUS_LOGGING_OLDFILES = 10

  #####################################################################
  # Markus Session Store configuration
  # see config/initializers/session_store.rb
  #####################################################################
  SESSION_COOKIE_NAME = '_markus_session'
  SESSION_COOKIE_SECRET = '650d281667d8011a3a6ad6dd4b5d4f9ddbce14a7d78b107812dbb40b24e234256ab2c5572c8196cf6cde6b85942688b6bfd337ffa0daee648d04e1674cf1fdf6'
  SESSION_COOKIE_EXPIRE_AFTER = 3.weeks
  SESSION_COOKIE_HTTP_ONLY = true
  SESSION_COOKIE_SECURE = false

  ###################################################################
  # END OF MarkUs SPECIFIC CONFIGURATION
  ###################################################################
end
