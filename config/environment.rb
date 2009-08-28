# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

###################################################################
# MarkUs SPECIFIC CONFIGURATION
#   - use "/" as path separator no matter what OS server is running
#   - settings have to be before Rails::Initializer.run in order
#     to be available in the app
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
VALIDATE_FILE = "#{RAILS_ROOT}/config/dummy_validate.sh"

###################################################################
# File storage (Repository) settings
###################################################################
# Options for Repository_type are 'svn' and 'memory' for now
# 'memory' is by design not persistent and only used for testing MarkUs
REPOSITORY_TYPE = "svn" # use Subversion as storage backend

###################################################################
# Directory where Repositories will be created. Make sure MarkUs is allowed
# to write to this directory
REPOSITORY_STORAGE = "/home/markus/svn-repos-root"

###################################################################
# Change this to 'REPOSITORY_EXTERNAL_SUBMITS_ONLY = true' if you
# are using Subversion as a storage backend and the instructor wants his/her
# students to submit to the repositories by command-line only. If you
# set this to true, students won't be able to submit via the Web interface.
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
$REPOSITORY_SVN_AUTHZ_FILE = REPOSITORY_STORAGE + "/svn_authz"

###################################################################
# This setting configures if MarkUs is reading Subversion
# repositories' permissions only OR is admin of the Subversion
# repositories. In the latter case, it will write to
# $REPOSITORY_SVN_AUTHZ_FILE, otherwise it doesn't. Change this to
# 'false' if repositories are created by a third party. 
IS_REPOSITORY_ADMIN = true

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
USER_STUDENT_CSV_UPLOAD_ORDER = [:user_name, :last_name, :first_name]
# Order of graders CSV uploads
USER_TA_CSV_UPLOAD_ORDER  = [:user_name, :last_name, :first_name]

###################################################################
# Date/Time display formats
###################################################################
# Short form (displays month, day, year)
SHORT_DATE_TIME_FORMAT = "%B %d, %Y"
# Long form (displays month, day, year, hour, minute)
LONG_DATE_TIME_FORMAT = "%B %d, %Y: %I:%M%p"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  #config.gem 'iridesco-time-warp', :lib => 'time_warp', :source => "http://gems.github.com"


  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  config.plugins = [ :ssl_requirement, :auto_complete, :calendar_date_select, :all ]

  # If you are hosting your application at path
  # http://hostname/path/to/markus set this to '/path/to/markus'
  # Ignore URL prefix specified below
  # config.action_controller.relative_url_root = ""

  # Add additional load paths for your own custom dirs.
  # Set it if you are using ruby libs and/or gems
  # at non-standard paths
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'Eastern Time (US & Canada)'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_markus_session',
    :secret      => '650d281667d8011a3a6ad6dd4b5d4f9ddbce14a7d78b107812dbb40b24e234256ab2c5572c8196cf6cde6b85942688b6bfd337ffa0daee648d04e1674cf1fdf6'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  
  
  #config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source  =>
#"http://gems.github.com", :version => '>= 2.0.6' 
end

ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>" }

CalendarDateSelect.format = :iso_date

###################################################################
# END OF MarkUs SPECIFIC CONFIGURATION
###################################################################
