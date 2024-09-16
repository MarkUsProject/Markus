# frozen_string_literal: true

module ActiveJob
  module Status
    class Storage
      def initialize(options = {})
        options.assert_valid_keys(:expires_in, :throttle_interval)

        @expires_in = options[:expires_in]
        @throttle = ActiveJob::Status::Throttle.new(options[:throttle_interval])
      end

      def store
        @store ||= ActiveJob::Status.store
      end

      def job_id(job)
        job.is_a?(String) ? job : job.job_id
      end

      def key(job)
        "activejob:status:#{job_id(job)}"
      end

      def read(job)
        store.read(key(job)) || {}
      end

      def write(job, message, force: false)
        @throttle.wrap(force: force) do
          store.write(key(job), message, expires_in: @expires_in)
        end
      end

      def update(job, message, force: false)
        @throttle.wrap(force: force) do
          message = read(job).merge(message)
          store.write(key(job), message, expires_in: @expires_in)
        end
      end

      def delete(job)
        store.delete(key(job))
      end
    end
  end
end
