# This file is used by Rack-based servers to start the application.

require File.expand_path('config/environment', __dir__)
# Required for managing scheduled jobs via web interface
use Rack::MethodOverride
map ENV['RAILS_RELATIVE_URL_ROOT'] || '/' do
  run Markus::Application
end
