# frozen_string_literal: true

require 'httparty'

module ExceptionNotifier
  class GoogleChatNotifier < BaseNotifier
    def call(exception, opts = {})
      options = base_options.merge(opts)
      formatter = Formatter.new(exception, options)

      HTTParty.post(
        options[:webhook_url],
        body: { text: body(exception, formatter) }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    private

    def body(exception, formatter)
      text = [
        "\nApplication: *#{formatter.app_name}*",
        formatter.subtitle,
        '',
        formatter.title,
        "*#{exception.message.tr('`', "'")}*"
      ]

      if (request = formatter.request_message.presence)
        text << ''
        text << '*Request:*'
        text << request
      end

      if (backtrace = formatter.backtrace_message.presence)
        text << ''
        text << '*Backtrace:*'
        text << backtrace
      end

      text.compact.join("\n")
    end
  end
end
