# frozen_string_literal: true

require 'logger'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/attribute_accessors'
require 'exception_notifier/base_notifier'
require 'exception_notifier/modules/error_grouping'

module ExceptionNotifier
  include ErrorGrouping

  autoload :BacktraceCleaner, 'exception_notifier/modules/backtrace_cleaner'
  autoload :Formatter, 'exception_notifier/modules/formatter'

  autoload :Notifier, 'exception_notifier/notifier'
  autoload :EmailNotifier, 'exception_notifier/email_notifier'
  autoload :HipchatNotifier, 'exception_notifier/hipchat_notifier'
  autoload :WebhookNotifier, 'exception_notifier/webhook_notifier'
  autoload :IrcNotifier, 'exception_notifier/irc_notifier'
  autoload :SlackNotifier, 'exception_notifier/slack_notifier'
  autoload :MattermostNotifier, 'exception_notifier/mattermost_notifier'
  autoload :TeamsNotifier, 'exception_notifier/teams_notifier'
  autoload :SnsNotifier, 'exception_notifier/sns_notifier'
  autoload :GoogleChatNotifier, 'exception_notifier/google_chat_notifier'
  autoload :DatadogNotifier, 'exception_notifier/datadog_notifier'

  class UndefinedNotifierError < StandardError; end

  # Define logger
  mattr_accessor :logger
  @@logger = Logger.new(STDOUT)

  # Define a set of exceptions to be ignored, ie, dont send notifications when any of them are raised.
  mattr_accessor :ignored_exceptions
  @@ignored_exceptions = %w[
    ActiveRecord::RecordNotFound Mongoid::Errors::DocumentNotFound AbstractController::ActionNotFound
    ActionController::RoutingError ActionController::UnknownFormat ActionController::UrlGenerationError
  ]

  mattr_accessor :testing_mode
  @@testing_mode = false

  class << self
    # Store conditions that decide when exceptions must be ignored or not.
    @@ignores = []

    # Store by-notifier conditions that decide when exceptions must be ignored or not.
    @@by_notifier_ignores = {}

    # Store notifiers that send notifications when exceptions are raised.
    @@notifiers = {}

    def testing_mode!
      self.testing_mode = true
    end

    def notify_exception(exception, options = {}, &block)
      return false if ignored_exception?(options[:ignore_exceptions], exception)
      return false if ignored?(exception, options)

      if error_grouping
        errors_count = group_error!(exception, options)
        return false unless send_notification?(exception, errors_count)
      end

      notification_fired = false
      selected_notifiers = options.delete(:notifiers) || notifiers
      [*selected_notifiers].each do |notifier|
        unless notifier_ignored?(exception, options, notifier: notifier)
          fire_notification(notifier, exception, options.dup, &block)
          notification_fired = true
        end
      end

      notification_fired
    end

    def register_exception_notifier(name, notifier_or_options)
      if notifier_or_options.respond_to?(:call)
        @@notifiers[name] = notifier_or_options
      elsif notifier_or_options.is_a?(Hash)
        create_and_register_notifier(name, notifier_or_options)
      else
        raise ArgumentError, "Invalid notifier '#{name}' defined as #{notifier_or_options.inspect}"
      end
    end
    alias add_notifier register_exception_notifier

    def unregister_exception_notifier(name)
      @@notifiers.delete(name)
    end

    def registered_exception_notifier(name)
      @@notifiers[name]
    end

    def notifiers
      @@notifiers.keys
    end

    # Adds a condition to decide when an exception must be ignored or not.
    #
    #   ExceptionNotifier.ignore_if do |exception, options|
    #     not Rails.env.production?
    #   end
    def ignore_if(&block)
      @@ignores << block
    end

    def ignore_notifier_if(notifier, &block)
      @@by_notifier_ignores[notifier] = block
    end

    def ignore_crawlers(crawlers)
      ignore_if do |_exception, opts|
        opts.key?(:env) && from_crawler(opts[:env], crawlers)
      end
    end

    def clear_ignore_conditions!
      @@ignores.clear
      @@by_notifier_ignores.clear
    end

    private

    def ignored?(exception, options)
      @@ignores.any? { |condition| condition.call(exception, options) }
    rescue Exception => e
      raise e if @@testing_mode

      logger.warn(
        "An error occurred when evaluating an ignore condition. #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      )
      false
    end

    def notifier_ignored?(exception, options, notifier:)
      return false unless @@by_notifier_ignores.key?(notifier)

      condition = @@by_notifier_ignores[notifier]
      condition.call(exception, options)
    rescue Exception => e
      raise e if @@testing_mode

      logger.warn(<<~"MESSAGE")
        An error occurred when evaluating a by-notifier ignore condition. #{e.class}: #{e.message}
        #{e.backtrace.join("\n")}
      MESSAGE
      false
    end

    def ignored_exception?(ignore_array, exception)
      all_ignored_exceptions = (Array(ignored_exceptions) + Array(ignore_array)).map(&:to_s)
      exception_ancestors = exception.singleton_class.ancestors.map(&:to_s)
      !(all_ignored_exceptions & exception_ancestors).empty?
    end

    def fire_notification(notifier_name, exception, options, &block)
      notifier = registered_exception_notifier(notifier_name)
      notifier.call(exception, options, &block)
    rescue Exception => e
      raise e if @@testing_mode

      logger.warn(
        "An error occurred when sending a notification using '#{notifier_name}' notifier." \
        "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      )
      false
    end

    def create_and_register_notifier(name, options)
      notifier_classname = "#{name}_notifier".camelize
      notifier_class = ExceptionNotifier.const_get(notifier_classname)
      notifier = notifier_class.new(options)
      register_exception_notifier(name, notifier)
    rescue NameError => e
      raise UndefinedNotifierError,
            "No notifier named '#{name}' was found. Please, revise your configuration options. Cause: #{e.message}"
    end

    def from_crawler(env, ignored_crawlers)
      agent = env['HTTP_USER_AGENT']
      Array(ignored_crawlers).any? do |crawler|
        agent =~ Regexp.new(crawler)
      end
    end
  end
end
