# frozen_string_literal: true

module ActiveJob
  module Status
    class Progress
      attr_reader :job, :total, :progress

      delegate :[], :to_s, :to_json, :inspect, to: :to_h
      delegate :status, to: :job, prefix: true

      def initialize(job)
        @job = job
        @total = 100
        @progress = 0
      end

      def total=(num)
        @total = num
        job_status.update(to_h, force: true)
      end

      def progress=(num)
        @progress = num
        job_status.update(to_h, force: true)
      end

      def increment(num = 1)
        @progress += num
        job_status.update(to_h)
        self
      end

      def decrement(num = 1)
        @progress -= num
        job_status.update(to_h)
        self
      end

      def finish
        @progress = @total
        job_status.update(to_h, force: true)
        self
      end

      def to_h
        {progress: @progress, total: @total}
      end
    end
  end
end
