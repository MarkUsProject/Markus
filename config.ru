# This file is used by Rack-based servers to start the application.

require ::File.expand_path(File.join('..', 'config', 'environment'),  __FILE__)
run Markus::Application
