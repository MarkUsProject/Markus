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
gem 'activerecord-import'
gem 'auto_complete'
gem 'best_in_place'
gem 'coffee-script'
gem 'dynamic_form'
gem 'exception_notification'
gem 'gitolite'
gem 'i18n'
gem 'jquery-rails'
gem 'json'
gem 'minitest',"4.7.5", platforms: :ruby_20
gem 'prototype-rails' # FIXME: Will be needed with Rails3.1
gem 'rubyzip'
gem 'rugged'
gem 'strong_parameters' # NOTE: this goes away when upgrading to Rails4
gem 'will_paginate'
gem 'ya2yaml'

group :assets do
  gem 'autoprefixer-rails'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'execjs'
  gem 'libv8'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'therubyracer'
  gem 'tilt', '~> 1.3.7'
  gem 'uglifier',     '>= 1.0.3'
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
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'debugger', :platforms => :mri_19
  gem 'quiet_assets'
end

group :test do
  gem 'factory_girl_rails'
  gem 'machinist', '< 2'
  gem 'mocha', require: false
  gem 'rspec-rails', '~> 3.0'
  gem 'shoulda'
  gem 'simplecov'
  gem 'time-warp'
end

# Gems needed (wanted) for both development and test can be
# listed here
group :development, :test do
  gem 'byebug', :platforms => [:mri_20, :mri_21]
  gem 'faker' # required for database seeding
end

# Gems not needed at runtime should go here so that MarkUs does
# not waste time/memory loading them during boot
group :offline do
  gem 'railroady'
  gem 'rdoc'
  gem 'rubocop'
  gem 'thin'
end

# If you  plan to use unicorn servers for production
# make sure that this group is included. You don't need this
# group if you are using Phusion Passenger.
group :unicorn do
  gem 'unicorn'
end
