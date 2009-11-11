# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

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
VALIDATE_FILE = "#{RAILS_ROOT}/config/dummy_validate.sh"

###################################################################
# File storage (Repository) settings
###################################################################
# Options for Repository_type are 'svn' and 'memory' for now
# 'memory' is by design not persistent and only used for testing MarkUs
REPOSITORY_TYPE = "memory" # use Subversion as storage backend

###################################################################
# Directory where Repositories will be created. Make sure MarkUs is allowed
# to write to this directory
REPOSITORY_STORAGE = "/home/markus/someplace"

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
REPOSITORY_PERMISSION_FILE = REPOSITORY_STORAGE + "/dummy"

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
MARKUS_LOGGING_LOGFILE = "log/info_#{RAILS_ENV}.log"
# Name of the logfile that will carry error and fatal messages
MARKUS_LOGGING_ERRORLOGFILE = "log/error_#{RAILS_ENV}.log"
# This variable sets the number of old log files that will be kept
MARKUS_LOGGING_OLDFILES = 10

###################################################################
# END OF MarkUs SPECIFIC CONFIGURATION
###################################################################