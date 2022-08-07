# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically
# be available to Rake.

require File.expand_path('config/application', __dir__)
require 'rake'
require 'rdoc/task'
require 'resque/scheduler/tasks'

Markus::Application.load_tasks

# Run js:routes:typscript and i18n:js:export tasks before precompiling assets
# Otherwise routes.js and routes.d.ts files will not be created properly
namespace :javascript do
  task build: %w[i18n:js:export js:routes]
end
