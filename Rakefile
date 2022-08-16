# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically
# be available to Rake.

require File.expand_path('config/application', __dir__)
require 'rake'
require 'rdoc/task'
require 'resque/scheduler/tasks'

Markus::Application.load_tasks

# i18n-js v4 got rid of this task so we redefine it here for convenience
namespace :i18n do
  namespace :js do
    task export: :environment do
      I18nJS.call(config_file: Rails.root.join('config/i18n.yml'))
    end
  end
end

# Run js:routes:typscript and i18n:js:export tasks before precompiling assets
# Otherwise routes.js and routes.d.ts files will not be created properly
namespace :javascript do
  task build: %w[i18n:js:export js:routes]
end
