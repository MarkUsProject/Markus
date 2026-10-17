describe Tracing do
  describe '.enabled?' do
    it 'is false when OTEL_EXPORTER_OTLP_ENDPOINT is not set' do
      stub_const('ENV', ENV.to_h.except('OTEL_EXPORTER_OTLP_ENDPOINT'))
      expect(Tracing.enabled?).to be(false)
    end

    it 'is false when OTEL_EXPORTER_OTLP_ENDPOINT is blank' do
      stub_const('ENV', ENV.to_h.merge('OTEL_EXPORTER_OTLP_ENDPOINT' => ''))
      expect(Tracing.enabled?).to be(false)
    end

    it 'is true when OTEL_EXPORTER_OTLP_ENDPOINT is set' do
      stub_const('ENV', ENV.to_h.merge('OTEL_EXPORTER_OTLP_ENDPOINT' => 'http://otel-lgtm:4318'))
      expect(Tracing.enabled?).to be(true)
    end
  end

  describe '.configure' do
    let(:configurator) { instance_double(OpenTelemetry::SDK::Configurator, 'service_name=': nil, use_all: nil) }

    before do
      require 'opentelemetry/sdk'
      allow(OpenTelemetry::SDK).to receive(:configure).and_yield(configurator)
    end

    it 'sets the service name to markus' do
      expect(configurator).to receive(:service_name=).with('markus')
      Tracing.configure
    end

    it 'turns on all available instrumentation' do
      expect(configurator).to receive(:use_all)
      Tracing.configure
    end
  end
end
