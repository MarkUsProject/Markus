# frozen_string_literal: true

require 'test_helper'
require 'timecop'

class FormatterTest < ActiveSupport::TestCase
  setup do
    @exception = RuntimeError.new('test')
    Timecop.freeze('2018-12-09 12:07:16 UTC')
  end

  teardown do
    Timecop.return
  end

  #
  # #title
  #
  test 'title returns correct content' do
    formatter = ExceptionNotifier::Formatter.new(@exception)

    title = if defined?(::Rails) && ::Rails.respond_to?(:env)
              '⚠️ Error occurred in test ⚠️'
            else
              '⚠️ Error occurred ⚠️'
            end

    assert_equal title, formatter.title
  end

  #
  # #subtitle
  #
  test 'subtitle without accumulated error' do
    formatter = ExceptionNotifier::Formatter.new(@exception)
    assert_equal 'A *RuntimeError* occurred.', formatter.subtitle
  end

  test 'subtitle with accumulated error' do
    formatter = ExceptionNotifier::Formatter.new(@exception, accumulated_errors_count: 3)
    assert_equal '3 *RuntimeError* occurred.', formatter.subtitle
  end

  test 'subtitle with controller' do
    env = Rack::MockRequest.env_for(
      '/', 'action_controller.instance' => test_controller
    )

    formatter = ExceptionNotifier::Formatter.new(@exception, env: env)
    assert_equal 'A *RuntimeError* occurred in *home#index*.', formatter.subtitle
  end

  #
  # #app_name
  #
  test 'app_name defaults to Rails app name' do
    formatter = ExceptionNotifier::Formatter.new(@exception)

    if defined?(::Rails) && ::Rails.respond_to?(:application)
      assert_equal 'dummy', formatter.app_name
    else
      assert_nil formatter.app_name
    end
  end

  test 'app_name can be overwritten using options' do
    formatter = ExceptionNotifier::Formatter.new(@exception, app_name: 'test')
    assert_equal 'test', formatter.app_name
  end

  #
  # #request_message
  #
  test 'request_message when env set' do
    text = [
      '```',
      '* url : http://test.address/?id=foo',
      '* http_method : GET',
      '* ip_address : 127.0.0.1',
      '* parameters : {"id"=>"foo"}',
      '* timestamp : 2018-12-09 12:07:16 UTC',
      '```'
    ].join("\n")

    env = Rack::MockRequest.env_for(
      '/',
      'HTTP_HOST' => 'test.address',
      'REMOTE_ADDR' => '127.0.0.1',
      params: { id: 'foo' }
    )

    formatter = ExceptionNotifier::Formatter.new(@exception, env: env)
    assert_equal text, formatter.request_message
  end

  test 'request_message when env not set' do
    formatter = ExceptionNotifier::Formatter.new(@exception)
    assert_nil formatter.request_message
  end

  #
  # #backtrace_message
  #
  test 'backtrace_message when backtrace set' do
    text = [
      '```',
      "* app/controllers/my_controller.rb:53:in `my_controller_params'",
      "* app/controllers/my_controller.rb:34:in `update'",
      '```'
    ].join("\n")

    @exception.set_backtrace([
                               "app/controllers/my_controller.rb:53:in `my_controller_params'",
                               "app/controllers/my_controller.rb:34:in `update'"
                             ])

    formatter = ExceptionNotifier::Formatter.new(@exception)
    assert_equal text, formatter.backtrace_message
  end

  test 'backtrace_message when no backtrace' do
    formatter = ExceptionNotifier::Formatter.new(@exception)
    assert_nil formatter.backtrace_message
  end

  #
  # #controller_and_action
  #
  test 'correct controller_and_action if controller is present' do
    env = Rack::MockRequest.env_for(
      '/', 'action_controller.instance' => test_controller
    )

    formatter = ExceptionNotifier::Formatter.new(@exception, env: env)
    assert_equal 'home#index', formatter.controller_and_action
  end

  test 'controller_and_action is nil if no controller' do
    env = Rack::MockRequest.env_for('/')

    formatter = ExceptionNotifier::Formatter.new(@exception, env: env)
    assert_nil formatter.controller_and_action
  end

  def test_controller
    controller = mock('controller')
    controller.stubs(:action_name).returns('index')
    controller.stubs(:controller_name).returns('home')

    controller
  end
end
