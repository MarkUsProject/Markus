# frozen_string_literal: true

require 'httparty'

module ExceptionNotifier
  class MattermostNotifier < BaseNotifier
    def call(exception, opts = {})
      options = opts.merge(base_options)
      @exception = exception

      @formatter = Formatter.new(exception, options)

      @gitlab_url = options[:git_url]

      @env = options[:env] || {}

      payload = {
        text: message_text.compact.join("\n"),
        username: options[:username] || 'Exception Notifier'
      }

      payload[:icon_url] = options[:avatar] if options[:avatar]
      payload[:channel] = options[:channel] if options[:channel]

      httparty_options = options.except(
        :avatar, :channel, :username, :git_url, :webhook_url,
        :env, :accumulated_errors_count, :app_name
      )

      httparty_options[:body] = payload.to_json
      httparty_options[:headers] ||= {}
      httparty_options[:headers]['Content-Type'] = 'application/json'

      HTTParty.post(options[:webhook_url], httparty_options)
    end

    private

    attr_reader :formatter

    def message_text
      text = [
        '@channel',
        "### #{formatter.title}",
        formatter.subtitle,
        "*#{@exception.message}*"
      ]

      if (request = formatter.request_message.presence)
        text << '### Request'
        text << request
      end

      if (backtrace = formatter.backtrace_message.presence)
        text << '### Backtrace'
        text << backtrace
      end

      if (exception_data = @env['exception_notifier.exception_data'])
        text << '### Data'
        data_string = exception_data.map { |k, v| "* #{k} : #{v}" }.join("\n")
        text << "```\n#{data_string}\n```"
      end

      text << message_issue_link if @gitlab_url

      text
    end

    def message_issue_link
      link = [@gitlab_url, formatter.app_name, 'issues', 'new'].join('/')
      params = {
        'issue[title]' => ['[BUG] Error 500 :',
                           formatter.controller_and_action || '',
                           "(#{@exception.class})",
                           @exception.message].compact.join(' ')
      }.to_query

      "[Create an issue](#{link}/?#{params})"
    end
  end
end
