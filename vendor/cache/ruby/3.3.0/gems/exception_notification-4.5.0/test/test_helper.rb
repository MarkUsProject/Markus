# frozen_string_literal: true

require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'exception_notification'

require 'minitest/autorun'
require 'mocha/minitest'
require 'active_support/test_case'
require 'action_mailer'

ExceptionNotifier.testing_mode!
require 'support/exception_notifier_helper'

Time.zone = 'UTC'
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.append_view_path "#{File.dirname(__FILE__)}/support/views"
