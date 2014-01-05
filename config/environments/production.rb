# encoding: utf-8
# Settings specified here will take precedence over those in config/environment.rb
Markus::Application.configure do
  # rails will fallback to en, no matter what is set as config.i18n.default_locale
  # rails will fallback to config.i18n.default_locale translation
  config.i18n.fallbacks = true
  config.i18n.fallbacks = [:en]

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true
  # set this to false, if you want automatic reload of changed code

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new
  #
  config.log_level = :info
  # set log-level (:debug, :info, :warn, :error, :fatal)

  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor  = :uglifier
  config.assets.css_compressor = :scss

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = true
  # set to false to turn off traces
  config.action_view.debug_rjs                         = true
  config.action_controller.perform_caching             = true
  config.cache_classes                                 = true

  # Send emails in case of error
  # (see config/initializers/07_exception_notifier for email addresses configuration)
  config.action_mailer.perform_deliveries = true
  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true

  # Defaults to:
  config.action_mailer.delivery_method = :sendmail
  #config.action_mailer.sendmail_settings = {
  #  :location => '/usr/sbin/sendmail',
  #  :arguments => '-i -t'  }

  # or using smtp configuration
  #config.action_mailer.delivery_method = :smtp
  #config.action_mailer.smtp_settings = {
  #  :address              => "smtp.gmail.com",
  #  :port                 => 587,
  #  :domain               => 'gmail.com',
  #  :user_name            => '<username>',
  #  :password             => '<password>',
  #  :authentication       => 'plain',
  #  :enable_starttls_auto => true  }

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store # place where to put cached files is configured in config/environment.rb
  config.action_controller.allow_forgery_protection    = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host                  = "http://assets.example.com"

  # Show Deprecated Warnings (to :log or to :stderr)
  config.active_support.deprecation = :log


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
