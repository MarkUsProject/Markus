# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Loads lib repo stuff.
require 'repo/repository'
require 'repo/git_repository'
require 'repo/subversion_repository'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Ensure all new testing is done using the recommended expect syntax of
  # RSpec.
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Automatically infer an example group's spec type from the file location.
  config.infer_spec_type_from_file_location!

  # Include Factory Girl syntax to simplify calls to factory.
  config.include FactoryGirl::Syntax::Methods

  # Include generic helpers.
  config.include Helpers
  config.include AuthenticationHelper

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
  config.before :each do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end
  config.after :each do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Clean up any created file folders
  config.after(:each) do
    FileUtils.rm_rf(Dir["#{Rails.root}/data/test/repos/test_repo"])
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end

  RSpec::Matchers.define :same_time_within_ms do |e|
    match do |a|
      e.to_i == a.to_i
    end
  end

  # Get fixture_file_upload to work with RSPEC. See http://bit.ly/1yQfoS5
  config.include ActionDispatch::TestProcess
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
end
