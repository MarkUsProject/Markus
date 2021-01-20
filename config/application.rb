require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Settings in config/environments/* take precedence over those specified here.
# Application configuration can go into files in config/initializers
# -- all .rb files in that directory are automatically loaded after loading
# the framework and any gems in your application.
module Markus
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version
    config.load_defaults 6.0

    # Sensitive parameters which will be filtered from the log file
    config.filter_parameters += [:password]

    # Use json serializer for cookies
    config.action_dispatch.cookies_serializer = :json

    # Do not add autoload paths to load path.
    config.add_autoload_paths_to_load_path = false

    # Use RSpec as test framework
    config.generators do |g|
      g.test_framework :rspec
    end

    # Assets
    # Enable the asset pipeline.
    config.assets.enabled = true
    # Suppress logger output for asset requests.
    config.assets.quiet = true
    # Add Yarn node_modules folder to the asset load path.
    config.assets.paths << Rails.root.join('node_modules')

    # Settings below are configurable

    # Set the timezone
    config.time_zone = Settings.rails.time_zone

    # Use Resque for background jobs
    config.active_job.queue_adapter = Settings.rails.active_job.queue_adapter.to_sym

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
      Settings.rails.session_store.type.to_sym,
      key: Settings.rails.session_store.args.key,
      path: Settings.rails.session_store.args.path,
      expire_after: Settings.rails.session_store.args.expire_after.days,
      secure: Settings.rails.session_store.args.secure,
      same_site: Settings.rails.session_store.args.same_site.to_sym
    )

    # Email notifications
    config.action_mailer.delivery_method = Settings.rails.action_mailer.delivery_method.to_sym
    config.action_mailer.smtp_settings = Settings.rails.action_mailer.smtp_settings.to_h
    config.action_mailer.default_url_options = Settings.rails.action_mailer.default_url_options.to_h
    config.action_mailer.asset_host = Settings.rails.action_mailer.asset_host
    config.action_mailer.perform_deliveries = Settings.rails.action_mailer.perform_deliveries
    config.action_mailer.deliver_later_queue_name = Settings.rails.action_mailer.deliver_later_queue_name

    # Print deprecation notices to stderr.
    config.active_support.deprecation = Settings.rails.active_support.deprecation.to_sym

    # If false, your application's code is reloaded on every request.
    # This slows down response time but is perfect for development
    # since you don't have to restart the web server when you make code changes.
    config.cache_classes = Settings.rails.cache_classes

    # Do not eager load code on boot.
    config.eager_load = Settings.rails.eager_load

    # Show full error reports.
    config.consider_all_requests_local = Settings.rails.consider_all_requests_local

    # Set high verbosity of logger.
    config.log_level = Settings.rails.log_level

    # Location to write compiled assets
    config.assets.prefix = Settings.rails.assets.prefix

    # The settings above are required
    # The settings below may optionally be set depending on the current environment

    # Set redis as the Rails cache store
    if Settings.rails.cache_store == 'redis_cache_store'
      config.cache_store = Settings.rails.cache_store.to_sym, { url: Settings.redis.url }
    else
      config.cache_store = Settings.rails.cache_store&.to_sym
    end

    # Disable/enable caching
    config.perform_caching = Settings.rails.perform_caching

    # Add authorized host urls
    config.hosts << Settings.rails.hosts || []

    # Show where SQL queries were generated from.
    config.active_record.verbose_query_logs = Settings.rails.active_record.verbose_query_logs

    # TODO review initializers 01 and 02
    # TODO review markus custom config format
    # TODO handle namespaces properly for app/lib
    # TODO migrate all javascript to webpack
    # TODO try precompiled assets in production
    # TODO database pool connections and unicorn workers
  end
end
