# Load the rails application
require File.expand_path('../application', __FILE__)

# Fix TA pluralization
ActiveSupport::Inflector.inflections do |inflection| inflection.irregular "ta", "tas"
end

# Initialize the rails application
Markus::Application.initialize!
