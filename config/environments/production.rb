# we want to use the ruby debugger in production mode
require 'ruby-debug'

# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true # set this to false, if you want automatic reload of changed code

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new
#
config.log_level = :debug	# set log-level (:debug, :info, :warn, :error, :fatal)

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = true # set to false to turn off traces
config.action_view.debug_rjs			     = true
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store # place where to put cached files is configured in config/environment.rb
config.action_controller.allow_forgery_protection    = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false
