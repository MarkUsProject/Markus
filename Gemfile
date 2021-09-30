# Gemfile
#
# For production mode PostgreSQL option :
#   bundle install --without development test mysql sqlite
# For production mode MySQL option :
#   bundle install --without development test postgresql sqlite
#
# Make sure to declare at least one 'source'
source 'https://rubygems.org'

# Bundler requires these gems in all environments
gem 'puma'
gem 'rails', '~> 6.1.3.2'
gem 'sprockets'

# Models and database interactions
gem 'pluck_to_hash'

# CSS and JavaScript
gem 'autoprefixer-rails'
gem 'js-routes'
gem 'libv8'
gem 'sass-rails'
gem 'uglifier'
gem 'webpacker'

# Background tasks
gem 'activejob-status', git: 'https://github.com/inkstak/activejob-status.git'
gem 'resque'
gem 'resque-scheduler'

# Authorization
gem 'action_policy'

# Statistics
gem 'descriptive_statistics', require: 'descriptive_statistics/safe'
gem 'histogram'

# Internationalization
gem 'i18n'
gem 'i18n-js'
gem 'rails-i18n', '~> 6.0.0'

# Exam template requirements
gem 'combine_pdf'
gem 'prawn'
gem 'prawn-qrcode'
gem 'rmagick'
gem 'zxing_cpp', require: 'zxing'

# Ruby miscellany
gem 'json'
gem 'mini_mime'
gem 'net-ssh'
gem 'redcarpet'
gem 'rubyzip', require: 'zip'
gem 'rugged'

# Rails miscellany
gem 'activerecord-session_store'
gem 'cookies_eu'
gem 'rails-html-sanitizer'
gem 'responders'
gem 'activemodel-serializers-xml'
gem 'config'

# If you are a MarkUs developer and use PostgreSQL, make sure you have
# PostgreSQL header files installed (e.g. libpq-dev on Debian/Ubuntu).
# Then install your bundle by:
#   bundle install --without mysql sqlite
group :postgresql do
  gem 'pg'
end

# If you are a MarkUs developer and use MySQL, make sure you have
# MySQL header files installed (e.g. libmysqlclient-dev on Debian/Ubuntu).
# Then install your bundle by:
#   bundle install --without postgresql sqlite
group :mysql do
  gem 'mysql2'
end

# If you are a MarkUs developer and use SQLite, make sure you have
# SQLite header files installed (e.g. libsqlite3-dev on Debian/Ubuntu).
# Then install your bundle by:
#   bundle install --without postgresql mysql
group :sqlite do
  gem 'sqlite3'
end

# Gems only used for development should be listed here so that they
# are not loaded in other environments.
group :development do
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller' # supplement for better_errors
  gem 'bootsnap', require: false
  gem 'brakeman', require: false
  gem 'bullet'
  gem 'rails-erd'
end

group :test do
  gem 'factory_bot_rails'
  gem 'fuubar'
  gem 'machinist', '< 3'
  gem 'shoulda'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'time-warp'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'rails-controller-testing'
end

# Gems needed (wanted) for both development and test can be
# listed here
group :development, :test do
  gem 'byebug'
  gem 'i18n-tasks'
  gem 'rspec-rails', '~> 5.0.2'
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
  gem 'rubocop'
  gem 'rubocop-git'
  gem 'rubocop-performance'
end

# If you  plan to use unicorn servers for production
# make sure that this group is included. You don't need this
# group if you are using Phusion Passenger.
group :unicorn do
  gem 'unicorn'
end
