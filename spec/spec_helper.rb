# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.output_directory = 'coverage'
  c.lcov_file_name = 'lcov.info'
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])
SimpleCov.start do
  add_filter 'better_errors'
  add_filter 'bullet'
  add_filter 'rails_erd'
  add_filter 'subversion'
  add_filter 'svn'
end

ENV['RAILS_ENV'] ||= 'test'
ENV['NODE_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'action_policy/rspec'
require 'action_policy/rspec/dsl'
require 'net/ssh'
# Loads lib repo stuff.
require 'time-warp'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

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

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  config.filter_gems_from_backtrace(
    'actiontext',
    'rails-controller-testing'
  )

  # Include Factory Girl syntax to simplify calls to factory.
  config.include FactoryBot::Syntax::Methods

  # Include generic helpers.
  config.include Helpers
  config.include AuthenticationHelper
  config.include ActiveJob::TestHelper

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.after :each do |test|
    destroy_repos unless test.metadata[:keep_memory_repos]
    FactoryBot.rewind_sequences
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.render_views if ENV['RSPEC_RENDER_VIEWS'] == 'true'

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Clean up any created file folders
  config.after(:suite) do
    FileUtils.rm_rf(Dir["#{Rails.root}/data/test/exam_templates/*"])
  end

  RSpec::Matchers.define :same_time_within_ms do |e|
    match do |a|
      e.to_i == a.to_i
    end
  end

  # Automatically decode CSV response bodies.
  ActionDispatch::IntegrationTest.register_encoder :csv,
                                                   param_encoder: ->(params) { params },
                                                   response_parser: ->(body) { CSV.parse(body) }
end
