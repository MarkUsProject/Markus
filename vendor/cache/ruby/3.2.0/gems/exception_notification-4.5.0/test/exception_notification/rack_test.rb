# frozen_string_literal: true

require 'test_helper'

class RackTest < ActiveSupport::TestCase
  setup do
    @pass_app = Object.new
    @pass_app.stubs(:call).returns([nil, { 'X-Cascade' => 'pass' }, nil])

    @normal_app = Object.new
    @normal_app.stubs(:call).returns([nil, {}, nil])
  end

  teardown do
    ExceptionNotifier.reset_notifiers!
  end

  test 'should ignore "X-Cascade" header by default' do
    ExceptionNotifier.expects(:notify_exception).never
    ExceptionNotification::Rack.new(@pass_app).call({})
  end

  test 'should notify on "X-Cascade" = "pass" if ignore_cascade_pass option is false' do
    ExceptionNotifier.expects(:notify_exception).once
    ExceptionNotification::Rack.new(@pass_app, ignore_cascade_pass: false).call({})
  end

  test 'should assign error_grouping if error_grouping is specified' do
    refute ExceptionNotifier.error_grouping
    ExceptionNotification::Rack.new(@normal_app, error_grouping: true).call({})
    assert ExceptionNotifier.error_grouping
  end

  test 'should assign notification_trigger if notification_trigger is specified' do
    assert_nil ExceptionNotifier.notification_trigger
    ExceptionNotification::Rack.new(@normal_app, notification_trigger: ->(_i) { true }).call({})
    assert_respond_to ExceptionNotifier.notification_trigger, :call
  end

  if defined?(Rails) && Rails.respond_to?(:cache)
    test 'should set default cache to Rails cache' do
      ExceptionNotification::Rack.new(@normal_app, error_grouping: true).call({})
      assert_equal Rails.cache, ExceptionNotifier.error_grouping_cache
    end
  end

  test 'should ignore exceptions with Usar Agent in ignore_crawlers' do
    exception_app = Object.new
    exception_app.stubs(:call).raises(RuntimeError)

    env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; Crawlerbot/2.1;)' }

    begin
      ExceptionNotification::Rack.new(exception_app, ignore_crawlers: %w[Crawlerbot]).call(env)

      flunk
    rescue StandardError
      refute env['exception_notifier.delivered']
    end
  end

  test 'should ignore exceptions if ignore_if condition is met' do
    exception_app = Object.new
    exception_app.stubs(:call).raises(RuntimeError)

    env = {}

    begin
      ExceptionNotification::Rack.new(
        exception_app,
        ignore_if: ->(_env, exception) { exception.is_a? RuntimeError }
      ).call(env)

      flunk
    rescue StandardError
      refute env['exception_notifier.delivered']
    end
  end

  test 'should ignore exceptions with notifiers that satisfies ignore_notifier_if condition' do
    exception_app = Object.new
    exception_app.stubs(:call).raises(RuntimeError)

    notifier1_called = notifier2_called = false
    notifier1 = ->(_exception, _options) { notifier1_called = true }
    notifier2 = ->(_exception, _options) { notifier2_called = true }

    env = {}

    begin
      ExceptionNotification::Rack.new(
        exception_app,
        ignore_notifier_if: {
          notifier1: ->(_env, exception) { exception.is_a? RuntimeError }
        },
        notifier1: notifier1,
        notifier2: notifier2
      ).call(env)

      flunk
    rescue StandardError
      refute notifier1_called
      assert notifier2_called
    end
  end
end
