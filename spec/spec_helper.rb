# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
require 'simplecov-lcov'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

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
end

ENV['RAILS_ENV'] ||= 'test'
ENV['NODE_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'action_policy/rspec'
require 'action_policy/rspec/dsl'
require 'capybara/rspec'
require 'selenium/webdriver'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  warn e.to_s.strip
  exit 1
end

Capybara.register_driver :selenium_remote_chrome do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new(args: ['--no-sandbox', '--disable-gpu',
                                                                   '--window-size=1400,1400'])
  chrome_options.add_argument('--headless=new') unless ENV.fetch('DISABLE_HEADLESS_UI_TESTING', nil) == 'true'
  Capybara::Selenium::Driver.new(app, browser: :remote, url: 'http://localhost:9515', capabilities: [chrome_options])
end

Capybara.configure do |config|
  config.app_host = "http://localhost:#{ENV.fetch('CAPYBARA_SERVER_PORT', '3434')}"
  config.server_host = ENV.fetch('CAPYBARA_SERVER_HOST', '0.0.0.0')
  config.server_port = ENV.fetch('CAPYBARA_SERVER_PORT', '3434')
  config.default_max_wait_time = 30
  config.server = :puma
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

  # Ignore system tests by default unless they are explicitly run
  config.exclude_pattern = 'system/**/*_spec.rb'

  # Automatically infer an example group's spec type from the file location.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  config.filter_gems_from_backtrace(
    'actiontext',
    'factory_bot',
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

  config.before type: :system do
    # Override the default driver used by rspec system tests
    driven_by :selenium_remote_chrome

    SimpleCov.command_name 'system'
  end

  config.before :each, type: :request do
    host! 'localhost'
  end

  config.after do |test|
    destroy_repos unless test.metadata[:keep_memory_repos]
    FactoryBot.rewind_sequences
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.render_views if ENV.fetch('RSPEC_RENDER_VIEWS', nil) == 'true'

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Clean up any created file folders
  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.glob('data/test/exam_templates/*'))
  end

  RSpec::Matchers.define :same_time_within_ms do |t1|
    match do |t2|
      t1.to_i == t2.to_i
    end
  end

  # Automatically decode CSV response bodies.
  ActionDispatch::IntegrationTest.register_encoder :csv,
                                                   param_encoder: ->(params) { params },
                                                   response_parser: ->(body) { CSV.parse(body) }

  # Uncomment to enable Bullet logging
  # if Bullet.enable?
  #   config.before(:each) do
  #     Bullet.start_request
  #   end
  #
  #   config.after(:each) do
  #     Bullet.perform_out_of_channel_notifications if Bullet.notification?
  #     Bullet.end_request
  #   end
  # end
  config.include ActionCable::TestHelper

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = nil
  end

  # Turn on Timecop safe mode (requires block syntax for methods)
  Timecop.safe_mode = true
end
