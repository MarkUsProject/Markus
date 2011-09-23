# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Markus::Application.initialize!

# Use the local environments overrides if they exist
if File.exists?(File.join(File.dirname(__FILE__), 'local_environment_override.rb'))
  instance_eval File.read(File.join(File.dirname(__FILE__), 'local_environment_override.rb'))
end
