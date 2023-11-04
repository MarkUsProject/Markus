# Gemfile
#
# For production mode:
#   bundle install --without development test
#
# Make sure to declare at least one 'source'
source 'https://rubygems.org'

# Bundler requires these gems in all environments
gem 'puma'
gem 'rails', '~> 7.1.1'
gem 'sprockets'
gem 'sprockets-rails'

# Models and database interactions
gem 'pluck_to_hash'

# CSS and JavaScript
gem 'autoprefixer-rails'
gem 'jsbundling-rails'
gem 'js-routes'
gem 'sass-rails'
gem 'terser'

# Background tasks
gem 'activejob-status'
gem 'resque'
gem 'resque-scheduler'

# Authorization
gem 'action_policy'
gem 'rack-cors'

# Statistics
gem 'descriptive_statistics', require: 'descriptive_statistics/safe'
gem 'histogram'

# Internationalization
gem 'i18n'
gem 'i18n-js'
gem 'rails-i18n', '~> 7.0.0'

# Redis
gem 'redis', '~> 4.8.1'

# Exam template requirements
gem 'combine_pdf'
gem 'prawn'
gem 'prawn-qrcode'
gem 'rmagick', '~> 5.3.0'
gem 'rtesseract'

# Ruby miscellany
gem 'json'
gem 'mini_mime'
gem 'redcarpet'
gem 'rubyzip', require: 'zip'
gem 'rugged'

# Rails miscellany
gem 'activemodel-serializers-xml'
gem 'activerecord-session_store'
gem 'config'
gem 'cookies_eu'
gem 'exception_notification'
gem 'rails-html-sanitizer'
gem 'rails_performance'
gem 'responders'

# LTI and OAuth
gem 'jwt'

# Postgres
gem 'pg'

# Gems only used for development should be listed here so that they
# are not loaded in other environments.
group :development do
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller' # supplement for better_errors
  gem 'bootsnap', require: false
  gem 'brakeman', require: false
  gem 'listen' # to listen for changes in i18n-js files
end

group :test do
  gem 'factory_bot_rails'
  gem 'fuubar'
  gem 'machinist', '< 3'
  gem 'rails-controller-testing'
  gem 'shoulda'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'time-warp'
  gem 'webmock'
end

# Gems needed (wanted) for both development and test can be
# listed here
group :development, :test do
  gem 'bullet'
  gem 'capybara'
  gem 'debug', '>= 1.0.0'
  gem 'i18n-tasks'
  gem 'rspec-rails', '~> 6.0.3'
  gem 'selenium-webdriver'
end

# Gems needed (wanted) for development, test and production_test
# can be listed here
# production_test is for testing a production-like deployment,
# but using a seeded database
group :development, :test, :production_test do
  gem 'faker' # required for database seeding
end

# Gems not needed at runtime should go here so that MarkUs does
# not waste time/memory loading them during boot
group :offline do
  gem 'railroady'
  gem 'rdoc'
end

# If you  plan to use unicorn servers for production
# make sure that this group is included. You don't need this
# group if you are using Phusion Passenger or Puma.
group :unicorn do
  gem 'unicorn'
end
