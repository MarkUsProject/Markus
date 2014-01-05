# encoding: utf-8
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
  # The following line can be commented out when jQuery is fully implemented in MarkUs
  #  config.action_view.debug_rjs                         = true
  #  config.action_controller.perform_caching             = false
  #  config.action_controller.allow_forgery_protection    = true

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

  require 'ruby-debug' if RUBY_VERSION == "1.8.7"
  require 'debugger' if RUBY_VERSION > "1.9"

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 1.0
end
