# Gemfile
# For production mode :
#   bundle install --without development test
#
# Make sure to decleare at least one 'source'
source 'http://rubygems.org'

# Bundler requires these gems in all environments
gem "rails", "2.3.8"
gem "db_populate"
gem "rubyzip"
gem "ya2yaml"
gem "i18n" 
gem "will_paginate"
gem "fastercsv"
gem "mongrel_cluster"

# To use debugger
group :development, :test do
  gem "shoulda"
  gem "selenium-client", "~>1.2.15"
  gem "machinist"
  gem "faker"
  gem "factory_data_preloader"
  gem "time-warp"
  gem "ruby-debug"
  gem 'sqlite3-ruby', :require => 'sqlite3'
end
