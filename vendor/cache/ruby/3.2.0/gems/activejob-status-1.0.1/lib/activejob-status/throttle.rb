# frozen_string_literal: true

module ActiveJob
  module Status
    class Throttle
      def initialize(interval)
        @interval = interval
        @started_at = Time.current
      end

      def wrap(force: false)
        return yield if force || @interval.nil? || @interval.zero?

        now = Time.current
        elasped = now - @started_at
        return if @interval > elasped

        yield
        @started_at = now
      end
    end
  end
end
