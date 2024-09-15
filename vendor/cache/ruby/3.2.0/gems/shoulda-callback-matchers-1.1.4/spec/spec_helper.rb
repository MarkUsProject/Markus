require 'logger'

LOGGER = Logger.new STDOUT
TESTAPP_ROOT = Pathname.new File.expand_path('../tmp/aruba/testapp', __FILE__)
FileUtils.rm_rf TESTAPP_ROOT if File.exists? TESTAPP_ROOT

ENV['RAILS_ENV'] = 'test'
ENV['BUNDLE_GEMFILE'] ||= TESTAPP_ROOT.join('Gemfile')

LOGGER.info "Generating Rails app in #{TESTAPP_ROOT}..."
`rails new #{TESTAPP_ROOT}`
LOGGER.info "Done"

require TESTAPP_ROOT.join('config', 'environment')
require 'shoulda-callback-matchers'
require 'rspec/rails'

PROJECT_ROOT = Pathname.new File.expand_path('../..', __FILE__)
$LOAD_PATH << PROJECT_ROOT.join('lib')

Dir[PROJECT_ROOT.join('spec', 'support', '**', '*.rb')].each do |file|
  require file
end

# Run the migrations
LOGGER.info "Running the migrations for the testapp..."
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
LOGGER.info "Done"

RSpec.configure do |config|
  config.include ClassBuilder
  config.include ModelBuilder

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end