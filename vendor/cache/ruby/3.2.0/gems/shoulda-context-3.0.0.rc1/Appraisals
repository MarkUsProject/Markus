# Note: All of the dependencies here were obtained by running `rails new` with
# various versions of Rails and copying lines from the generated Gemfile. It's
# best to keep the gems here in the same order as they're listed there so you
# can compare them more easily.

shared_rails_dependencies = proc do
  gem "sqlite3", "~> 1.3.6"
end

shared_spring_dependencies = proc do
  gem "spring"
  gem "spring-commands-rspec"
end

shared_test_dependencies = proc do
  gem "minitest-reporters"
end

shared_dependencies = proc do
  instance_eval(&shared_rails_dependencies)
  instance_eval(&shared_spring_dependencies)
  instance_eval(&shared_test_dependencies)
end

appraise "rails_6_0" do
  instance_eval(&shared_dependencies)

  gem "rails", "~> 6.0.2"
  gem "puma", "~> 4.1"
  gem "sass-rails", ">= 6"
  gem "webpacker", "~> 4.0"
  gem "turbolinks", "~> 5"
  gem "jbuilder", "~> 2.7"
  gem "bcrypt", "~> 3.1.7"
  gem "bootsnap", ">= 1.4.2", require: false
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  gem "sqlite3", "~> 1.4.0"
  gem "webdrivers"

  # Other dependencies
  gem "rails-controller-testing", ">= 1.0.4"
  gem "pg", "~> 1.1", platform: :ruby
end

appraise "rails_6_1" do
  instance_eval(&shared_dependencies)

  gem "rails", "~> 6.1.3.2"
  gem "puma", "~> 5.0"
  gem "sass-rails", ">= 6"
  gem "turbolinks", "~> 5"
  gem "jbuilder", "~> 2.7"
  gem "bcrypt", "~> 3.1.7"
  gem "bootsnap", ">= 1.4.2", require: false
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  gem "sqlite3", "~> 1.4.0"
  gem "webdrivers"

  # Other dependencies
  gem "rails-controller-testing", ">= 1.0.4"
  gem 'pg', '>= 0.18', '< 2.0'
end
