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
gem 'rails', '~> 4.2.0'
gem 'rubyzip'
gem 'ya2yaml'
gem 'i18n'
gem 'i18n-js'
gem 'dynamic_form'
gem 'exception_notification'
gem 'activerecord-import'
gem 'upsert'
gem 'auto_complete'
gem 'best_in_place'
gem 'coffee-script'
gem 'webpacker', '~> 3.0'
gem 'rugged'
gem 'jquery-rails'
gem 'responders', '~> 2.0'
gem 'sprockets', '~> 2.12.0'
gem 'rails-html-sanitizer'
gem 'rails-deprecated_sanitizer'
gem 'redcarpet', '~> 3.0.0'

gem 'tilt', '~> 1.3.7'
gem 'sass-rails',   '5.0.0.beta1'
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier',     '>= 1.3.0'
gem 'execjs'
gem 'libv8'
gem 'therubyracer'
gem 'json'
gem 'minitest'
gem 'autoprefixer-rails'
gem 'resque'
gem 'redis-rails'
gem 'activejob-status', github: 'inkstak/activejob-status'
gem 'net-ssh'
gem 'pluck_to_hash'

gem 'actionpack-action_caching'
gem 'actionpack-page_caching', '~>1.0.0'
gem 'actionpack-xml_parser', '~>1.0.0'
gem 'actionview-encoded_mail_to', '~>1.0.4'
gem 'activerecord-session_store', '~>0.1.0'
gem 'rails-observers', '~>0.1.1'
gem 'rails-perftest', '~>0.0.2'
gem 'arel', '~>6.0.2'
gem 'jbuilder', '~> 2.0'

gem 'js-routes'

gem 'descriptive_statistics', '~> 2.4.0', :require => 'descriptive_statistics/safe'
gem 'histogram', '~> 0.2.4.1'

# Exam template requirements
gem 'prawn'
gem 'prawn-qrcode'
gem 'combine_pdf'
gem 'zxing_cpp'
gem 'rmagick'

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
  gem 'binding_of_caller'
  gem 'spring'
  gem 'quiet_assets'
  gem 'bullet'
end

group :test do
  gem 'factory_girl_rails'
  gem 'machinist', '< 2'
  gem 'mocha', require: false
  gem 'shoulda'
  gem 'simplecov'
  gem 'time-warp'
  gem 'database_cleaner'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'rails-controller-testing'
end

# Gems needed (wanted) for both development and test can be
# listed here
group :development, :test do
  gem 'byebug', :platforms => [:mri_20, :mri_21, :mri_22, :mri_23]
  gem "rspec-rails", '~> 3.5'
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
  gem 'thin'
end

# If you  plan to use unicorn servers for production
# make sure that this group is included. You don't need this
# group if you are using Phusion Passenger.
group :unicorn do
  gem 'unicorn'
end
