# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/hash"
require "active_support/core_ext/enumerable"
require "active_job"
require "activejob-status/storage"
require "activejob-status/status"
require "activejob-status/progress"
require "activejob-status/throttle"

module ActiveJob
  module Status
    extend ActiveSupport::Concern

    DEFAULT_OPTIONS = {
      expires_in: 60 * 30,
      throttle_interval: 0,
      includes: %i[status]
    }.freeze

    included do
      before_enqueue { |job| job.status.update_defaults(:queued) }
      before_perform { |job| job.status.update_defaults(:working) }
      after_perform { |job| job.status.update_defaults(:completed) }

      rescue_from(Exception) do |e|
        status.catch_exception(e)
        raise e
      end
    end

    def status
      @status ||= Status.new(self)
    end

    def progress
      @progress ||= Progress.new(self)
    end

    class << self
      def options=(options)
        options.assert_valid_keys(*DEFAULT_OPTIONS.keys)
        @@options = DEFAULT_OPTIONS.merge(options)
      end

      def options
        @@options ||= DEFAULT_OPTIONS
      end

      def store=(store)
        store = ActiveSupport::Cache.lookup_store(*store) if store.is_a?(Array) || store.is_a?(Symbol)
        @@store = store
      end

      def store
        @@store ||= (Rails.cache if defined?(Rails))
      end

      def get(id)
        Status.new(id)
      end
    end
  end
end
