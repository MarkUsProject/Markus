# Gemfile
#
# For production mode PostgreSQL option :
#   bundle install --without development test mysql sqlite
# For production mode MySQL option :
#   bundle install --without development test postgresql sqlite
#
# Make sure to decleare at least one 'source'
source 'http://rubygems.org'

# Bundler requires these gems in all environments
gem 'rails', '3.2.18'
gem 'rubyzip', '0.9.9'
gem 'ya2yaml'
gem 'i18n'
gem 'will_paginate'
gem 'dynamic_form'
# FIXME: The 'exception_notification' gem version 4
# is not compatible with Rails 3.0.x
gem 'exception_notification', '<4.0'
gem 'minitest',"4.7.5", :platforms => :ruby_20
gem 'calendar_date_select', :git => 'git://github.com/paneq/calendar_date_select.git'
gem 'auto_complete'
gem 'json'
gem 'coffee-script'
gem 'jquery-rails'
gem 'prototype-rails' # FIXME: Will be needed with Rails3.1

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

# Other development related required gems. You don't need them
# for production.
group :development, :test do
  gem 'rdoc'
  gem 'thin'
  gem 'simplecov'
# FIXME: shoulda (>=4.0) introduces several deprecation warnings in tests
  # we have to fix before doing an upgrade
  gem 'shoulda', '<3.4'
  # FIXME: shoulda-matchers (>= 2) is incompatible with Ruby 1.8
  # Remove next line once MarkUs will not support Ruby 1.8,
  # as shoulda-matchers is a dependency of shoulda
  gem 'shoulda-matchers', '~>1.5'
  gem 'shoulda-context', '~> 1.1.6'
  gem 'machinist', '< 2'
  gem 'faker'
  gem 'railroady'
  gem 'time-warp'
  gem 'debugger', :platforms => :mri_19
  gem 'byebug', :platforms => [:mri_20, :mri_21]
  gem 'mocha', :require => false
  gem 'quiet_assets'
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
  gem 'rghost'
end
