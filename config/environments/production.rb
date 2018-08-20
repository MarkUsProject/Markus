# Settings specified here will take precedence over those in config/application.rb
Markus::Application.configure do

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Set low verbosity of logger.
  config.log_level = :info

  # Ignore deprecation notices.
  config.active_support.deprecation = :silence

  # Caching is turned on.
  config.action_controller.perform_caching = true

  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor = Uglifier.new(harmony: true)
  config.assets.css_compressor = :sass

  # Set this to change the location of precompiled assets (RAILS_ENV=production bin/rails assets:precompile)
  # config.assets.prefix = '/assets'

  # Set this if MarkUs is deployed to a subdirectory, e.g. if it is served at https://yourhost.com/instance0
  # config.action_controller.relative_url_root = '/instance0'

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
  # is password). If VALIDATE_IP is true, markus will also pass the
  # remote ip address as a third line to stdin
  #
  # If and only if it exits with a return code of 0, the username/password
  # combination is considered valid and the user is authenticated. Moreover,
  # the user is authorized, if it exists as a user in MarkUs.
  #
  # That is why MarkUs does not allow usernames/passwords which contain
  # \n or \0. These are the only restrictions.
  VALIDATE_FILE = "#{::Rails.root.to_s}/config/dummy_validate.sh"

  VALIDATE_IP = false

  # Normally exit status 0 means successful, 1 means no such user,
  # and 2 means wrong password.
  # The following allows for one additional custom exit status which also
  # represents a failure to log in, but says so with a custom string.
  # It is commented out by default because there is no additional custom
  # exit status by default.
  #VALIDATE_CUSTOM_EXIT_STATUS = 38
  #VALIDATE_CUSTOM_STATUS_DISPLAY = 'You are a squid.  Only vertebrates may use MarkUs.'

  # Custom messages for "user not allowed" and "login incorrect",
  # overriding the default "login failed" message.  By default,
  # MarkUs does not distinguish these cases for security reasons.
  # If these variables are not defined (commented out), it uses the
  # standard "login failed" message for both situations.
  #VALIDATE_USER_NOT_ALLOWED_DISPLAY = 'That is your correct University of Foo user name and password, but you have not been added to this particular MarkUs database.  Please contact your instructor or check your course web page.'
  #VALIDATE_LOGIN_INCORRECT_DISPLAY = 'Login incorrect.  You can check your Foo U user name or reset your password at https://www.foo.example.edu/passwords.'

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
  # Options for Repository_type are 'svn','git' and 'mem'
  # 'mem' is by design not persistent and only used for testing MarkUs
  REPOSITORY_TYPE = 'svn'

  ###################################################################
  # Directory where Repositories will be created. Make sure MarkUs is allowed
  # to write to this directory
  REPOSITORY_STORAGE = "#{::Rails.root.to_s}/data/prod/repos"

  ###################################################################
  # A hash of repository hook scripts (used only when REPOSITORY_TYPE
  # is 'git'): the key is the hook id, the value is the hook script.
  # Make sure MarkUs is allowed to execute the hook scripts.
  REPOSITORY_HOOKS = {}
  # Path to the MarkUs client-side hooks (copied to all group repos).
  REPOSITORY_CLIENT_HOOKS = ''

  ###################################################################
  # Directory where authentication keys will be uploaded. Make sure MarkUs
  # is allowed to write to this directory
  KEY_STORAGE = "#{::Rails.root}/data/prod/keys"

  ###################################################################
  # Max file size for submissions in Bytes
  MAX_FILE_SIZE = 5000000

  ###################################################################
  # Change this to 'REPOSITORY_EXTERNAL_SUBMITS_ONLY = true' if you
  # are using Subversion as a storage backend and the instructor wants his/her
  # students to submit to the repositories Subversion clients only. Set this
  # to true if you intend to force students to submit via Subversion
  # clients only. The MarkUs Web interface for submissions will be read-only
  # in that case.
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
  # REPOSITORY_SVN_AUTHZ_FILE, otherwise it doesn't. Change this to
  # 'false' if repositories are created by a third party.
  IS_REPOSITORY_ADMIN = true

  ###################################################################
  # Starter code settings
  ###################################################################
  # Global flag to enable/disable starter code feature.
  EXPERIMENTAL_STARTER_CODE_ON = true

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
  USER_STUDENT_CSV_UPLOAD_ORDER = [:user_name, :last_name, :first_name, :section_name, :id_number, :email]
  # Order of graders CSV uploads
  USER_TA_CSV_UPLOAD_ORDER  = [:user_name, :last_name, :first_name]

  ###################################################################
  # Logging Options
  ###################################################################
  # If set to true then the MarkusLogger will be enabled
  MARKUS_LOGGING_ENABLED = true
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
  # Resque queues
  ###################################################################

  # The name of the queue where jobs to create individal groups for all students wait to be executed.
  JOB_CREATE_INDIVIDUAL_GROUPS_QUEUE_NAME = 'CSC108_job_groups'
  # The name of the queue where jobs to collect submissions wait to be executed.
  JOB_COLLECT_SUBMISSIONS_QUEUE_NAME = 'CSC108_job_collect'
  # The name of the queue where jobs to uncollect submissions wait to be executed.
  JOB_UNCOLLECT_SUBMISSIONS_QUEUE_NAME = 'CSC108_job_uncollect'
  # The name of the queue where jobs to update repos with the list of required files wait to be executed.
  JOB_UPDATE_REPO_REQUIRED_FILES_QUEUE_NAME = 'CSC108_job_req_files'
  JOB_GENERATE_QUEUE_NAME = 'CSC108_job_generate'
  JOB_SPLIT_PDF_QUEUE_NAME = 'CSC108_job_split_pdf'

  ###################################################################
  # Automated Testing Engine settings
  ###################################################################

  # Look at https://github.com/MarkUsProject/markus-autotesting for the documentation
  AUTOTEST_ON = true
  AUTOTEST_STUDENT_TESTS_ON = true
  AUTOTEST_STUDENT_TESTS_BUFFER_TIME = 1.hour
  AUTOTEST_CLIENT_DIR = "#{::Rails.root}/data/prod/autotest"
  AUTOTEST_SERVER_HOST = 'localhost'
  AUTOTEST_SERVER_USERNAME = nil
  AUTOTEST_SERVER_DIR = "#{::Rails.root}/../markus-autotesting/server/workspace"
  AUTOTEST_SERVER_COMMAND = 'autotest_enqueuer'
  AUTOTEST_RUN_QUEUE = 'CSC108_autotest_run'
  AUTOTEST_CANCEL_QUEUE = 'CSC108_autotest_cancel'
  AUTOTEST_SCRIPTS_QUEUE = 'CSC108_autotest_scripts'

  ###################################################################
  # Exam Plugin settings
  ###################################################################
  # Global flag to enable/disable all exam plugin features.
  EXPERIMENTAL_EXAM_PLUGIN_ON = false
  EXAM_TEMPLATE_DIR = "#{::Rails.root}/data/prod/exam_templates"

  ###################################################################
  # END OF MarkUs SPECIFIC CONFIGURATION
  ###################################################################
end
