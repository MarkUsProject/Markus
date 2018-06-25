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
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    # Generate translations.js file (for i18n-js gem).
    config.middleware.use I18n::JS::Middleware
    # Set the timezone
    config.time_zone = 'Eastern Time (US & Canada)'

    #TODO review initializers
    #TODO precompiled assets
    #TODO database pool connections
    # Set this if MarkUs is not hosted under / of your Web-host.
    # E.g. if MarkUs should be accessible by http://yourhost.com/markus/instance0
    # then set the below directive to "/markus/instance0".
    # config.action_controller.relative_url_root = ENV['RAILS_RELATIVE_URL_ROOT']

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.quiet = true

    # Validate passed locales
    I18n.enforce_available_locales = true
    I18n.available_locales = [:en, :es, :fr, :pt]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # flash keys for responder flash
    config.responders.flash_keys = [:success, :error]
    config.app_generators.scaffold_controller :responders_controller

    config.active_job.queue_adapter = :resque
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
