# Export traces of requests, background jobs and the database queries, views and other work inside them with
# OpenTelemetry. This is controlled by the telemetry settings (see "Viewing Traces in Development" in the docs).
class Tracing
  # Resque performs each job in a forked process that exits without running at_exit hooks, so this sends the job's
  # spans before that process exits. (The Active Job instrumentation's force_flush option does not do this.)
  module FlushSpansAfterJob
    def perform(job_data)
      super
    ensure
      OpenTelemetry.tracer_provider.force_flush
    end
  end

  def self.enabled?
    Settings.telemetry.enabled
  end

  def self.configure
    require 'opentelemetry/sdk'
    require 'opentelemetry/exporter/otlp'
    require 'opentelemetry/instrumentation/rack'
    require 'opentelemetry/instrumentation/rails'
    require 'opentelemetry/instrumentation/pg'
    require 'opentelemetry/instrumentation/redis'
    require 'opentelemetry/instrumentation/net/http'

    OpenTelemetry::SDK.configure do |c|
      c.service_name = 'markus'
      c.add_span_processor(
        OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
          OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: "#{Settings.telemetry.endpoint.chomp('/')}/v1/traces")
        )
      )
      c.use 'OpenTelemetry::Instrumentation::Rack'
      c.use 'OpenTelemetry::Instrumentation::ActionPack'
      c.use 'OpenTelemetry::Instrumentation::ActionView'
      c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
      c.use 'OpenTelemetry::Instrumentation::ActiveJob'
      c.use 'OpenTelemetry::Instrumentation::PG'
      c.use 'OpenTelemetry::Instrumentation::Redis'
      c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
    end
    ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper.singleton_class.prepend(FlushSpansAfterJob)
  end
end

Tracing.configure if Tracing.enabled?
