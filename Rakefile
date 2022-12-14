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

# Run js:routes and i18n:js:export tasks before precompiling assets
# Otherwise routes.js and routes.d.ts files will not be created properly
#
# Also replace the javascript:build rake task since the default task
# requires that yarn be installed and used to install assets.
Rake::Task['javascript:build'].clear

namespace :javascript do
  task build: %w[i18n:js:export js:routes] do
    unless system 'npm ci --include=dev && npm run build && npm prune'
      raise 'jsbundling-rails: Command build failed, ensure npm is installed and `npm run build` runs without errors'
    end
  end
end
