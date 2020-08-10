# Settings specified here will take precedence over those in config/application.rb
Markus::Application.configure do

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Set high verbosity of logger.
  config.log_level = :debug

  # Print deprecation notices to stderr
  config.active_support.deprecation = :stderr

  # Disable caching.
  config.action_controller.perform_caching = false

  # Explicitly whitelist available locales for i18n-js.
  I18n.available_locales = [:en, :fr, :es, :pt]

  # Set default locale.
  I18n.default_locale = :en

  # Markus Session Store configuration
  # Be sure to restart your server when you modify this part.
  #
  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  # Please make sure :_key is named uniquely if you are hosting
  # several MarkUs instances on one machine. Also, make sure you change
  # the :secret string to something else than you find below.
  Rails.application.config.session_store(
      :cookie_store,
      key: '_markus_session',
      path: '/',
      expire_after: 3.weeks,
      secure: false,
      same_site: :lax
  )

  ###################################################################
  # MarkUs SPECIFIC CONFIGURATION
  #   - use "/" as path separator no matter what OS server is running
  ###################################################################

  ###################################################################
  # Set the course name here
  config.course_name = "CSC108 Fall 2009: Introduction to Computer Programming"

  ###################################################################
  # MarkUs relies on external user authentication: An external script
  # (ideally a small C program) is called with username and password
  # piped to stdin of that program (first line is username, second line
  # is password). If validate_ip is true, markus will also pass the
  # remote ip address as a third line to stdin
  #
  # If and only if it exits with a return code of 0, the username/password
  # combination is considered valid and the user is authenticated. Moreover,
  # the user is authorized, if it exists as a user in MarkUs.
  #
  # That is why MarkUs does not allow usernames/passwords which contain
  # \n or \0. These are the only restrictions.
  config.validate_file = "#{::Rails.root}/config/dummy_validate.sh"

  config.validate_ip = false

  # Normally exit status 0 means successful, 1 means no such user,
  # and 2 means wrong password.
  # The following allows for one additional custom exit status which also
  # represents a failure to log in, but says so with a custom string.
  # It is commented out by default because there is no additional custom
  # exit status by default.
  config.validate_custom_exit_status = nil
  config.validate_custom_status_message = nil

  # Custom messages for "user not allowed" and "login incorrect",
  # overriding the default "login failed" message.  By default,
  # MarkUs does not distinguish these cases for security reasons.
  # If these variables are nil, it uses the
  # standard "login failed" message for both situations.
  config.validate_user_not_allowed_message = nil
  config.incorrect_login_message = nil

  ###################################################################
  # Authentication Settings
  ###################################################################
  # Set this to true/false if you want to use an external authentication scheme
  # that sets the REMOTE_USER variable.
  config.remote_user_auth = false

  ###################################################################
  # This is where the logout button will redirect to when clicked.
  # Set this to one of the three following options:
  #
  # "DEFAULT" - MarkUs will use its default logout routine.
  # A logout link will be provided.
  #
  # The DEFAULT option should not be used if remote_user_auth is set to true,
  # as it will not result in a successful logout.
  #
  # -----------------------------------------------------------------------------
  #
  # "http://address.of.choice" - Logout will redirect to the specified URI.
  #
  # If remote_user_auth is set to true, it would be possible
  # to specify a custom address which would log the user out of the authentication
  # scheme.
  # Choosing this option with remote_user_auth is set to false will still properly
  # log the user out of MarkUs.
  #
  # -----------------------------------------------------------------------------
  #
  # "NONE" - Logout link will be hidden.
  #
  # It only recommended that you use this if remote_user_auth is set to true
  # and do not have a custom logout page.
  #
  # If you are using HTTP's basic authentication, you probably want to use this
  # option.

  config.logout_redirect = "DEFAULT"

  ###################################################################
  # File storage (Repository) settings
  ###################################################################
  # Options for Repository_type are 'svn' and 'memory'
  # 'mem' is by design not persistent and only used for testing MarkUs
  config.x.repository.type = 'mem'

  config.data_dir = ENV.fetch('MARKUS_DATA_DIR') { "#{::Rails.root.to_s}/data/test" }
  config.x.repository.git_shell = ENV.fetch('MARKUS_REPOSITORY_GIT_SHELL') { '/usr/bin/git-shell' }

  ###################################################################
  # Directory where Repositories will be created. Make sure MarkUs is allowed
  # to write to this directory
  config.x.repository.storage = "#{config.data_dir}/repos"

  ###################################################################
  # A hash of repository hook scripts (used only when repository.type
  # is 'git'): the key is the hook id, the value is the hook script.
  # Make sure MarkUs is allowed to execute the hook scripts.
  config.x.repository.hooks = {}
  # Path to the MarkUs client-side hooks (copied to all group repos).
  config.x.repository.client_hooks = ''

  ###################################################################
  # Directory where authentication keys will be uploaded.
  # Make sure MarkUs is allowed to write to this directory
  config.key_storage = "#{config.data_dir}/keys"
  config.x.queues.update_keys = "CSC108"

  # Max file size for submission files, in bytes
  config.max_file_size = 5000000

  ###################################################################
  # Change this to true if you are using version control as a storage backend and the instructor wants their
  # students to submit to the repositories using version control only. The MarkUs Web interface for submissions
  # will be read-only in that case.
  config.x.repository.external_submits_only = false

  ###################################################################
  # This config setting only makes sense, if you are using
  # 'config.x.repository.external_submits_only = true'. If you have Apache httpd
  # configured so that the repositories created by MarkUs will be available to
  # the outside world, this is the URL which internally "points" to the
  # config.x.repository.storage directory configured earlier. Hence, Subversion
  # repositories will be available to students for example via URL
  # http://www.example.com/markus/svn/Repository_Name. Make sure the path
  # after the hostname matches your <Location> directive in your Apache
  # httpd configuration
  config.x.repository.url = "http://www.example.com/markus/svn"
  config.x.repository.ssh_url = ENV.fetch('MARKUS_REPOSITORY_SSH_URL') { 'git@example.com/csc108' }

  ###################################################################
  # This setting is important for two scenarios:
  # First, if MarkUs should use Subversion repositories created by a
  # third party, point it to the place where it will find the Subversion
  # authz file. In that case, MarkUs would need at least read access to
  # that file.
  # Second, if MarkUs is configured with config.x.repository.external_submits_only
  # set to 'true', you can configure as to where MarkUs should write the
  # Subversion authz file.
  config.x.repository.permission_file = ENV.fetch('MARKUS_REPOSITORY_PERMISSION_FILE') {
    File.join(config.x.repository.storage, 'dummy')
  }

  ###################################################################
  # This setting configures if MarkUs is reading Subversion
  # repositories' permissions only OR is admin of the Subversion
  # repositories. In the latter case, it will write to
  # REPOSITORY_SVN_AUTHZ_FILE, otherwise it doesn't. Change this to
  # 'false' if repositories are created by a third party.
  config.x.repository.is_repository_admin = true

  ###################################################################
  # Session Timeouts
  ###################################################################
  config.student_session_timeout        = 1800 # Timeout for student users
  config.ta_session_timeout             = 1800 # Timeout for grader users
  config.admin_session_timeout          = 1800 # Timeout for admin users

  ###################################################################
  # CSV upload order of fields (usually you don't want to change this)
  ###################################################################
  # Order of student CSV uploads
  config.student_csv_upload_order = [:user_name, :last_name, :first_name, :section_name, :id_number, :email]
  # Order of graders CSV uploads
  config.ta_csv_upload_order = [:user_name, :last_name, :first_name, :email]

  ###################################################################
  # Logging Options
  ###################################################################
  # If set to true then the MarkusLogger will be enabled
  # MarkusLogger-related tests will fail if set to false
  config.x.logging.enabled = true
  # If set to true then the rotation of the logfiles will be defined
  # by config.x.logging.rotate_interval instead of the size of the file
  config.x.logging.rotate_by_interval = false
  # Sets the interval which rotations will occur if
  # config.x.logging.rotate_by_interval is set to true,
  # possible values are: 'daily', 'weekly', 'monthly'
  config.x.logging.rotate_interval = 'daily'
  # Set the maximum size file that the logfiles will have before rotating
  config.x.logging.size_threshold = 1_024_000_000
  # Name of the logfile that will carry information, debugging and
  # warning messages
  config.x.logging.log_file = "log/info_#{::Rails.env}.log"
  # Name of the logfile that will carry error and fatal messages
  config.x.logging.error_file = "log/error_#{::Rails.env}.log"
  # This variable sets the number of old log files that will be kept
  config.x.logging.old_files = 10

  ###################################################################
  # Email Notifications
  ###################################################################
  config.action_mailer.delivery_method = :test
  config.action_mailer.asset_host = 'http://localhost:3000'
  config.action_mailer.default_url_options = {host: 'localhost:3000'}
  config.action_mailer.perform_deliveries = true
  config.action_mailer.deliver_later_queue_name = 'CSC108'

  ###################################################################
  # Resque queues
  ###################################################################
  config.active_job.queue_adapter = :test

  # The name of the queue where jobs to create groups wait to be executed.
  config.x.queues.create_groups = 'CSC108'
  # The name of the queue where jobs to collect submissions wait to be executed.
  config.x.queues.collect_submissions = 'CSC108'
  # The name of the queue where jobs to download submissions wait to be executed.
  config.x.queues.download_submissions = 'CSC108'
  # The name of the queue where jobs to uncollect submissions wait to be executed.
  config.x.queues.uncollect_submissions = 'CSC108'
  # The name of the queue where jobs to update repos with the list of required files wait to be executed.
  config.x.queues.repo_required_files = 'CSC108'
  config.x.queues.exam_generate = 'CSC108'
  config.x.queues.split_pdf = 'CSC108'

  ###################################################################
  # Automated Testing Engine settings
  ###################################################################

  # Look at https://github.com/MarkUsProject/markus-autotesting for the documentation
  config.x.autotest.enable = true
  config.x.autotest.student_test_buffer = 1.hour
  config.x.autotest.client_dir = "#{config.data_dir}/autotest"
  config.x.autotest.server_host = ENV.fetch('AUTOTEST_SERVER_HOST') { 'localhost' }
  config.x.autotest.server_username =  ENV.fetch('AUTOTEST_SERVER_USERNAME') { nil }
  config.x.autotest.server_command = 'autotest_enqueuer'
  config.x.queues.autotest_run = 'CSC108'
  config.x.queues.autotest_cancel = 'CSC108'
  config.x.queues.autotest_specs = 'CSC108'
  config.x.queues.autotest_testers = 'CSC108'

  ###################################################################
  # Exam Plugin settings
  ###################################################################
  # Global flag to enable/disable all exam plugin features.
  config.x.scanned_exams.enable = true
  config.x.scanned_exams.path = "#{config.data_dir}/exam_templates"
  config.x.scanned_exams.python = "#{::Rails.root}/lib/scanner/venv/bin/python"

  ###################################################################
  # Starter file setttings
  ###################################################################

  config.x.starter_file.storage = "#{config.data_dir}/starter_files"

  ###################################################################
  # END OF MarkUs SPECIFIC CONFIGURATION
  ###################################################################
end
