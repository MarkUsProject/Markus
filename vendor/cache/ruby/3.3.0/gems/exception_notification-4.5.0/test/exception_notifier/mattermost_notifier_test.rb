# frozen_string_literal: true

require 'test_helper'
require 'httparty'
require 'timecop'
require 'json'

class MattermostNotifierTest < ActiveSupport::TestCase
  URL = 'http://localhost:8000'

  def setup
    Timecop.freeze('2018-12-09 12:07:16 UTC')
  end

  def teardown
    Timecop.return
  end

  test 'should send notification if properly configured' do
    opts = {
      body: default_body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)
    notifier.call ArgumentError.new('foo')
  end

  test 'should send notification with create issue link if specified' do
    body = default_body.merge(
      text: [
        '@channel',
        error_occurred_in,
        'An *ArgumentError* occurred.',
        '*foo*',
        github_link
      ].join("\n")
    )

    opts = {
      body: body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)
    notifier.call ArgumentError.new('foo'), git_url: 'github.com/aschen'
  end

  test 'should add username and icon_url params to the notification if specified' do
    body = default_body.merge(
      username: 'Test Bot',
      icon_url: 'http://site.com/icon.png'
    )

    opts = {
      body: body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)
    notifier.call(
      ArgumentError.new('foo'),
      username: 'Test Bot',
      avatar: 'http://site.com/icon.png'
    )
  end

  test 'should add other HTTParty options to params' do
    opts = {
      basic_auth: {
        username: 'clara',
        password: 'password'
      },
      body: default_body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)
    notifier.call(
      ArgumentError.new('foo'),
      basic_auth: {
        username: 'clara',
        password: 'password'
      }
    )
  end

  test "should use 'An' for exceptions count if :accumulated_errors_count option is nil" do
    opts = {
      body: default_body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)
    notifier.call(ArgumentError.new('foo'))
  end

  test 'shoud use direct errors count if :accumulated_errors_count option is 5' do
    body = default_body.merge(
      text: [
        '@channel',
        error_occurred_in,
        '5 *ArgumentError* occurred.',
        '*foo*'
      ].join("\n")
    )

    opts = {
      body: body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)
    notifier.call(ArgumentError.new('foo'), accumulated_errors_count: 5)
  end

  test 'should include backtrace and request info' do
    body = default_body.merge(text: [
      '@channel',
      error_occurred_in,
      'An *ArgumentError* occurred.',
      '*foo*',
      request_info,
      backtrace_info
    ].join("\n"))

    opts = {
      body: body.to_json,
      headers: default_headers
    }

    HTTParty.expects(:post).with(URL, opts)

    exception = ArgumentError.new('foo')
    exception.set_backtrace([
                              "app/controllers/my_controller.rb:53:in `my_controller_params'",
                              "app/controllers/my_controller.rb:34:in `update'"
                            ])

    notifier.call(exception, env: test_env)
  end

  test 'should include exception_data_info' do
    body = default_body.merge(
      text: [
        '@channel',
        error_occurred_in,
        'An *ArgumentError* occurred.',
        '*foo*',
        request_info,
        exception_data_info
      ].join("\n")
    )

    opts = {
      body: body.to_json,
      headers: default_headers
    }

    env = test_env.merge(
      'exception_notifier.exception_data' => { foo: 'bar', john: 'doe' }
    )

    HTTParty.expects(:post).with(URL, opts)
    notifier.call(ArgumentError.new('foo'), env: env)
  end

  private

  def notifier
    ExceptionNotifier::MattermostNotifier.new(webhook_url: URL)
  end

  def default_body
    {
      text: [
        '@channel',
        error_occurred_in,
        'An *ArgumentError* occurred.',
        '*foo*'
      ].join("\n"),
      username: 'Exception Notifier'
    }
  end

  def default_headers
    { 'Content-Type' => 'application/json' }
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

  def error_occurred_in
    if defined?(::Rails) && ::Rails.respond_to?(:env)
      '### ⚠️ Error occurred in test ⚠️'
    else
      '### ⚠️ Error occurred ⚠️'
    end
  end

  def github_link
    if defined?(::Rails) && ::Rails.respond_to?(:application)
      '[Create an issue]' \
      '(github.com/aschen/dummy/issues/new/?issue%5Btitle%5D=%5BBUG%5D+Error+500+%3A++%28ArgumentError%29+foo)'
    else
      # TODO: fix missing app name
      '[Create an issue]' \
      '(github.com/aschen//issues/new/?issue%5Btitle%5D=%5BBUG%5D+Error+500+%3A++%28ArgumentError%29+foo)'
    end
  end

  def request_info
    [
      '### Request',
      '```',
      '* url : http://test.address/?id=foo',
      '* http_method : GET',
      '* ip_address : 127.0.0.1',
      '* parameters : {"id"=>"foo"}',
      '* timestamp : 2018-12-09 12:07:16 UTC',
      '```'
    ]
  end

  def backtrace_info
    [
      '### Backtrace',
      '```',
      "* app/controllers/my_controller.rb:53:in `my_controller_params'",
      "* app/controllers/my_controller.rb:34:in `update'",
      '```'
    ]
  end

  def exception_data_info
    [
      '### Data',
      '```',
      '* foo : bar',
      '* john : doe',
      '```'
    ]
  end
end
