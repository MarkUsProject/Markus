# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'exception_notification'

class SinatraApp < Sinatra::Base
  use Rack::Config do |env|
    # This is highly recommended.  It will prevent the ExceptionNotification email from including your users' passwords
    env['action_dispatch.parameter_filter'] = [:password]
  end

  use ExceptionNotification::Rack,
      email: {
        email_prefix: '[Example] ',
        sender_address: %("notifier" <notifier@example.com>),
        exception_recipients: %w[exceptions@example.com],
        smtp_settings: {
          address: 'localhost',
          port: 1025
        }
      }

  get '/' do
    raise StandardError, "ERROR: #{params[:error]}" unless params[:error].blank?

    'Everything is fine! Now, lets break things clicking <a href="/?error=ops"> here </a>.' \
    'Dont forget to see the emails at <a href="http://localhost:1080">mailcatcher</a> !'
  end

  get '/background_notification' do
    begin
      1 / 0
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { msg: 'Cannot divide by zero!' })
    end
    'Check email at <a href="http://localhost:1080">mailcatcher</a>.'
  end
end
