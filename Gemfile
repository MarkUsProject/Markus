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
gem 'rails', '3.2.18'
gem 'rubyzip'
gem 'ya2yaml'
gem 'i18n'
gem 'will_paginate'
gem 'dynamic_form'
gem 'exception_notification'
gem 'minitest',"4.7.5", platforms: :ruby_20
gem 'auto_complete'
gem 'json'
gem 'coffee-script'
gem 'jquery-rails'
gem 'prototype-rails' # FIXME: Will be needed with Rails3.1
gem 'rugged'
gem 'gitolite'
gem 'activerecord-import'
gem 'strong_parameters' # NOTE: this goes away when upgrading to Rails4

gem 'best_in_place'

group :assets do
  gem 'tilt', '~> 1.3.7'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'
  gem 'execjs'
  gem 'libv8'
  gem 'therubyracer'
end


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
  gem 'mysql2', '>=0.3'
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
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'awesome_print'
  gem 'debugger', :platforms => :mri_19
end

group :test do
  gem 'simplecov'
  gem 'shoulda'
  gem 'machinist', '< 2'
  gem 'time-warp'
  gem 'mocha', require: false
  gem 'rspec-rails', '~> 3.0'
  gem 'factory_girl_rails'
end

# Gems needed (wanted) for both development and test can be
# listed here
group :development, :test do
  gem 'faker' # required for database seeding
  gem 'byebug', :platforms => [:mri_20, :mri_21]
end

# Gems not needed at runtime should go here so that MarkUs does
# not waste time/memory loading them during boot
group :offline do
  gem 'rdoc'
  gem 'railroady'
  gem 'thin'
  gem 'rubocop'
end

# If you  plan to use unicorn servers for production
# make sure that this group is included. You don't need this
# group if you are using Phusion Passenger.
group :unicorn do
  gem 'unicorn'
end
