require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'active_support/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Markus
  class Application < Rails::Application

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # See Rails::Configuration for more options.

    # Set this if MarkUs is not hosted under / of your Web-host.
    # E.g. if MarkUs should be accessible by http://yourhost.com/markus/instance0
    # then set the below directive to "/markus/instance0".
    # config.action_controller.relative_url_root = ENV['RAILS_RELATIVE_URL_ROOT']

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    #
    # Having a default time-zone configured is required, in order to have Time.zone available,
    # which is used in the assignments_controller.rb
    config.time_zone = 'Eastern Time (US & Canada)'

    # We need some additional load paths (e.g. for the API)
    # Note for developers: in Ruby %W( a b c ) is equivalent to [ 'a', 'b', 'c' ]
    config.autoload_paths += %W(
                                #{::Rails.root}/lib
                                #{::Rails.root}/app
                                #{::Rails.root}/controllers/api
                                #{::Rails.root}/lib/classes
                                #{::Rails.root}/lib/validators
                                )
    # Load any local configuration that is kept out of source control
    # (e.g. gems, patches).
    if File.exists?(File.join(File.dirname(__FILE__), 'local_environment_override.rb'))
     instance_eval File.read(File.join(File.dirname(__FILE__), 'local_environment_override.rb'))
    end
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.version = '1.0'

    # Validate passed locales
    I18n.enforce_available_locales = true
    I18n.available_locales = [:en, :es, :fr, :pt]

    config.active_job.queue_adapter = :resque
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
