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
    config.load_defaults 5.2

    # Configure sensitive parameters which will be filtered from the log file
    config.filter_parameters += [:password]

    # Set the timezone
    config.time_zone = 'Eastern Time (US & Canada)'

    # Add all config/locales subdirs
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # Use Resque for background jobs
    config.active_job.queue_adapter = :resque

    # Use json serializer for cookies
    config.action_dispatch.cookies_serializer = :json

    # Use RSpec as test framework
    config.generators do |g|
      g.test_framework :rspec
    end

    #TODO review initializers 01 and 02
    #TODO review markus custom config format
    #TODO precompiled assets
    #TODO database pool connections and unicorn workers
    # Enable the asset pipeline
    config.assets.enabled = true
    # Version of your assets, change this if you want to expire all your assets.
    config.assets.version = '1.0'
    # Suppress logger output for asset requests.
    config.assets.quiet = true
    # Add Yarn node_modules folder to the asset load path.
    config.assets.paths << Rails.root.join('node_modules')
    # precompile additional assets
    config.assets.precompile = %w(manifest.js)
    # Do not fallback to assets pipeline if a precompiled asset is missed.
   # config.assets.compile = false #TODO production?
  end
end
