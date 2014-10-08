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
gem 'rails', '~> 4.0.0'
gem 'rubyzip'
gem 'ya2yaml'
gem 'i18n'
gem 'will_paginate'
gem 'dynamic_form'
gem 'exception_notification'
gem "minitest-rails", "~> 1.0"
gem 'auto_complete'
gem 'json'
gem 'coffee-script'
gem 'jquery-rails'
gem 'prototype-rails', '~> 4.0.0'
gem 'activerecord-import'
gem 'sprockets', '2.11.0'
gem 'rails4_upgrade'

gem 'tilt', '~> 1.3.7'
gem 'sass-rails',   '4.0.1'
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier',     '>= 1.3.0'
gem 'execjs'
gem 'libv8'
gem 'therubyracer'

gem 'actionpack-action_caching', '~>1.0.0'
gem 'actionpack-page_caching', '~>1.0.0'
gem 'actionpack-xml_parser', '~>1.0.0'
gem 'actionview-encoded_mail_to', '~>1.0.4'
gem 'activerecord-session_store', '~>0.0.1'
gem 'activeresource', '~>4.0.0.beta1'
gem 'rails-observers', '~>0.1.1'
gem 'rails-perftest', '~>0.0.2'

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
  gem 'debugger', :platforms => :mri_19
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

# If you want to be able to view and annotate PDF files,
# make sure that this group is included. GhostScript has to be
# installed for rghost to work well. You also need to set
# the PDF_SUPPORT bool to true in the config file(s).
group :rghost do
  gem 'rghost', '<=0.9.3'
end
