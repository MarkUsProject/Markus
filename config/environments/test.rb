# encoding: utf-8
# Settings specified here will take precedence over those in config/environment.rb
Markus::Application.configure do
  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  config.log_level = :debug
  # set log-level (:debug, :info, :warn, :error, :fatal)

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Show Deprecated Warnings (to :log or to :stderr)
  config.active_support.deprecation = :stderr

  require 'ruby-debug' if RUBY_VERSION == "1.8.7"
  require 'debugger' if RUBY_VERSION > "1.9"

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 1.0


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
  # END OF MarkUs SPECIFIC CONFIGURATION
  ###################################################################
end
