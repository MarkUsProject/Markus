# frozen_string_literal: true

# -------------------------------------------
# To run the application: ruby examples/sample_app.rb
# -------------------------------------------

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'rails', '5.0.0'
  gem 'exception_notification', '4.3.0'
  gem 'httparty', '0.15.7'
end

class SampleApp < Rails::Application
  config.middleware.use ExceptionNotification::Rack,
                        webhook: {
                          url: 'http://example.com'
                        }

  config.secret_key_base = 'my secret key base'

  Rails.logger = Logger.new($stdout)

  routes.draw do
    get '/', to: 'exceptions#index'
  end
end

require 'action_controller/railtie'

class ExceptionsController < ActionController::Base
  def index
    raise 'Sample exception raised, you should receive a notification!'
  end
end

require 'minitest/autorun'

class Test < Minitest::Test
  include Rack::Test::Methods

  def test_raise_exception
    get '/'

    assert last_response.server_error?
  end

  private

  def app
    Rails.application
  end
end
