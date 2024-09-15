# frozen_string_literal: true

require 'test_helper'
require 'rack'
require 'httparty'
require 'timecop'
require 'json'

class GoogleChatNotifierTest < ActiveSupport::TestCase
  URL = 'http://localhost:8000'

  def setup
    Timecop.freeze('2018-12-09 12:07:16 UTC')
  end

  def teardown
    Timecop.return
  end

  test 'should send notification if properly configured' do
    HTTParty.expects(:post).with(URL, post_opts("#{header}\n#{body}"))
    notifier.call ArgumentError.new('foo')
  end

  test 'shoud use errors count if accumulated_errors_count is provided' do
    text = [
      '',
      "Application: *#{app_name}*",
      '5 *ArgumentError* occurred.',
      '',
      body
    ].join("\n")

    HTTParty.expects(:post).with(URL, post_opts(text))

    notifier.call(ArgumentError.new('foo'), accumulated_errors_count: 5)
  end

  test 'Message request should be formatted as hash' do
    text = [
      header,
      body,
      '',
      '*Request:*',
      '```',
      '* url : http://test.address/?id=foo',
      '* http_method : GET',
      '* ip_address : 127.0.0.1',
      '* parameters : {"id"=>"foo"}',
      '* timestamp : 2018-12-09 12:07:16 UTC',
      '```'
    ].join("\n")

    HTTParty.expects(:post).with(URL, post_opts(text))

    notifier.call(ArgumentError.new('foo'), env: test_env)
  end

  test 'backtrace with less than 3 lines should be displayed fully' do
    text = [
      header,
      body,
      '',
      backtrace
    ].join("\n")

    HTTParty.expects(:post).with(URL, post_opts(text))

    exception = ArgumentError.new('foo')
    exception.set_backtrace([
                              "app/controllers/my_controller.rb:53:in `my_controller_params'",
                              "app/controllers/my_controller.rb:34:in `update'"
                            ])

    notifier.call(exception)
  end

  test 'backtrace with more than 3 lines should display only top 3 lines' do
    text = [
      header,
      body,
      '',
      '*Backtrace:*',
      '```',
      "* app/controllers/my_controller.rb:99:in `specific_function'",
      "* app/controllers/my_controller.rb:70:in `specific_param'",
      "* app/controllers/my_controller.rb:53:in `my_controller_params'",
      '```'
    ].join("\n")

    HTTParty.expects(:post).with(URL, post_opts(text))

    exception = ArgumentError.new('foo')
    exception.set_backtrace([
                              "app/controllers/my_controller.rb:99:in `specific_function'",
                              "app/controllers/my_controller.rb:70:in `specific_param'",
                              "app/controllers/my_controller.rb:53:in `my_controller_params'",
                              "app/controllers/my_controller.rb:34:in `update'"
                            ])

    notifier.call(exception)
  end

  test 'Get text with backtrace and request info' do
    text = [
      header,
      body,
      '',
      '*Request:*',
      '```',
      '* url : http://test.address/?id=foo',
      '* http_method : GET',
      '* ip_address : 127.0.0.1',
      '* parameters : {"id"=>"foo"}',
      '* timestamp : 2018-12-09 12:07:16 UTC',
      '```',
      '',
      backtrace
    ].join("\n")

    HTTParty.expects(:post).with(URL, post_opts(text))

    exception = ArgumentError.new('foo')
    exception.set_backtrace([
                              "app/controllers/my_controller.rb:53:in `my_controller_params'",
                              "app/controllers/my_controller.rb:34:in `update'"
                            ])

    notifier.call(exception, env: test_env)
  end

  private

  def notifier
    ExceptionNotifier::GoogleChatNotifier.new(webhook_url: URL)
  end

  def post_opts(text)
    {
      body: { text: text }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  end

  def test_env
    Rack::MockRequest.env_for(
      '/',
      'HTTP_HOST' => 'test.address',
      'REMOTE_ADDR' => '127.0.0.1',
      'HTTP_USER_AGENT' => 'Rails Testing',
      params: { id: 'foo' }
    )
  end

  def header
    [
      '',
      "Application: *#{app_name}*",
      'An *ArgumentError* occurred.',
      ''
    ].join("\n")
  end

  def body
    if defined?(::Rails) && ::Rails.respond_to?(:env)
      "⚠️ Error occurred in test ⚠️\n*foo*"
    else
      "⚠️ Error occurred ⚠️\n*foo*"
    end
  end

  def app_name
    'dummy' if defined?(::Rails) && ::Rails.respond_to?(:application)
  end

  def backtrace
    [
      '*Backtrace:*',
      '```',
      "* app/controllers/my_controller.rb:53:in `my_controller_params'",
      "* app/controllers/my_controller.rb:34:in `update'",
      '```'
    ]
  end
end
