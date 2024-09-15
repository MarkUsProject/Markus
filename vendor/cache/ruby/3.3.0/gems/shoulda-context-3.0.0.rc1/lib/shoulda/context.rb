require "shoulda/context/autoload_macros"
require "shoulda/context/configuration"
require "shoulda/context/context"
require "shoulda/context/dsl"
require "shoulda/context/proc_extensions"
require "shoulda/context/test_framework_detection"
require "shoulda/context/version"
require "shoulda/context/world"

if defined?(Rails)
  require "shoulda/context/railtie"
end

Shoulda::Context.configure do |config|
  config.include(Shoulda::Context::DSL)
end
