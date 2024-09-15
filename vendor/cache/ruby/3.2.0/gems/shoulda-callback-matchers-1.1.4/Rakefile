require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'appraisal'

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rspec_opts = '--color --format progress'
  t.verbose = false
end

desc 'Test the plugin'
task :all => ["appraisal:cleanup", "appraisal:install"] do
  exec('rake appraisal spec')
end

desc 'Default: run specs'
task :default => [:all]
