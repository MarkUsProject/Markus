# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  config.plugins = [ :ssl_requirement, :auto_complete, :calendar_date_select ]

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

  # Bundler handles our gem dependencies
  config.gem 'bundler', :version => ">=1.0.0", :source => "http://rubygems.org"

  # We need some additional load paths (e.g. for the API)
  #   Note for developers: in Ruby %W( a b c ) is equivalent to [ 'a', 'b', 'c' ]
  config.load_paths += %W(
                            app/controllers/api
                            lib/classes
                         )
end
