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

    config.time_zone = Settings.rails.time_zone

    config.active_job.queue_adapter = Settings.rails.active_job.queue_adapter.to_sym

    Rails.application.config.session_store(
      Settings.rails.session_store.type.to_sym,
      key: Settings.rails.session_store.args.key,
      path: Settings.rails.session_store.args.path,
      expire_after: Settings.rails.session_store.args.expire_after.days,
      secure: Settings.rails.session_store.args.secure,
      same_site: Settings.rails.session_store.args.same_site.to_sym
    )

    config.action_mailer.delivery_method = Settings.rails.action_mailer.delivery_method.to_sym
    config.action_mailer.smtp_settings = Settings.rails.action_mailer.smtp_settings.to_h
    config.action_mailer.sendmail_settings = Settings.rails.action_mailer.sendmail_settings.to_h
    config.action_mailer.file_settings = Settings.rails.action_mailer.file_settings.to_h
    config.action_mailer.default_url_options = Settings.rails.action_mailer.default_url_options.to_h
    config.action_mailer.asset_host = Settings.rails.action_mailer.asset_host
    config.action_mailer.perform_deliveries = Settings.rails.action_mailer.perform_deliveries
    deliver_later_queue = Settings.rails.action_mailer.deliver_later_queue_name || Settings.queues.default
    config.action_mailer.deliver_later_queue_name = deliver_later_queue

    config.active_support.deprecation = Settings.rails.active_support.deprecation.to_sym

    config.cache_classes = Settings.rails.cache_classes

    config.eager_load = Settings.rails.eager_load

    config.consider_all_requests_local = Settings.rails.consider_all_requests_local

    config.log_level = Settings.rails.log_level

    config.assets.prefix = Settings.rails.assets.prefix

    config.force_ssl = Settings.rails.force_ssl

    # The settings above are required
    # The settings below may optionally be set depending on the current environment

    if Settings.rails.cache_store == 'redis_cache_store'
      config.cache_store = Settings.rails.cache_store.to_sym, { url: Settings.redis.url }
    else
      config.cache_store = Settings.rails.cache_store&.to_sym
    end

    config.action_controller.perform_caching = Settings.rails.action_controller&.perform_caching

    config.hosts.push(*Settings.rails.hosts)

    config.active_record.verbose_query_logs = Settings.rails.active_record.verbose_query_logs

    # TODO review initializers 01 and 02
    # TODO review markus custom config format
    # TODO handle namespaces properly for app/lib
    # TODO migrate all javascript to webpack
    # TODO try precompiled assets in production
    # TODO database pool connections and unicorn workers
  end
end
