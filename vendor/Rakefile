# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'rdoc/task'

# TODO REMOVE THIS FIX WITH RAKE 0.9:0
module ::Markus
  class Application
    include Rake::DSL
  end
end

module ::RakeFileUtils
  extend Rake::FileUtilsExt
end
######## END OF FIX

Markus::Application.load_tasks
