# Export traces of requests, background jobs and the database queries, views and other work inside them with
# OpenTelemetry. This is only enabled when an OTLP endpoint is set (for example, by compose.otel.yaml).
if ENV['OTEL_EXPORTER_OTLP_ENDPOINT'].present?
  require 'opentelemetry/sdk'
  require 'opentelemetry/exporter/otlp'
  require 'opentelemetry/instrumentation/all'

  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'markus'
    c.use_all
  end
end
