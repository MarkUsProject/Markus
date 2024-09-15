# frozen_string_literal: true

require 'exception_notifier'
require 'exception_notification/rack'
require 'exception_notification/version'

module ExceptionNotification
  # Alternative way to setup ExceptionNotification.
  # Run 'rails generate exception_notification:install' to create
  # a fresh initializer with all configuration values.
  def self.configure
    yield ExceptionNotifier
  end
end
