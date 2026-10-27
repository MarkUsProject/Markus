describe Tracing do
  describe '.enabled?' do
    it 'is false when telemetry is disabled' do
      allow(Settings.telemetry).to receive(:enabled).and_return(false)
      expect(Tracing.enabled?).to be(false)
    end

    it 'is true when telemetry is enabled' do
      allow(Settings.telemetry).to receive(:enabled).and_return(true)
      expect(Tracing.enabled?).to be(true)
    end
  end

  describe '.configure' do
    let(:configurator) do
      instance_double(OpenTelemetry::SDK::Configurator, 'service_name=': nil, add_span_processor: nil)
    end
    let(:exporter) { instance_double(OpenTelemetry::Exporter::OTLP::Exporter) }
    let(:span_processor) { instance_double(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor) }
    let(:job_wrapper) { ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper }

    before do
      require 'opentelemetry/sdk'
      require 'opentelemetry/exporter/otlp'
      allow(Settings.telemetry).to receive(:endpoint).and_return('http://otel.example.com:4318/')
      allow(OpenTelemetry::SDK).to receive(:configure).and_yield(configurator)
      allow(OpenTelemetry::Exporter::OTLP::Exporter).to receive(:new).and_return(exporter)
      allow(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor).to receive(:new)
        .with(exporter).and_return(span_processor)
      allow(job_wrapper.singleton_class).to receive(:prepend)
    end

    it 'sets the service name to markus' do
      allow(configurator).to receive(:use)
      expect(configurator).to receive(:service_name=).with('markus')
      Tracing.configure
    end

    it 'exports spans to the traces path of the telemetry endpoint' do
      allow(configurator).to receive(:use)
      expect(OpenTelemetry::Exporter::OTLP::Exporter).to receive(:new)
        .with(endpoint: 'http://otel.example.com:4318/v1/traces').and_return(exporter)
      expect(configurator).to receive(:add_span_processor).with(span_processor)
      Tracing.configure
    end

    it 'turns on only the listed instrumentation' do
      %w[Rack ActionPack ActionView ActiveRecord ActiveJob PG Redis Net::HTTP].each do |name|
        expect(configurator).to receive(:use).with("OpenTelemetry::Instrumentation::#{name}")
      end
      expect(configurator).not_to receive(:use_all)
      Tracing.configure
    end

    it 'flushes spans after each Resque job' do
      allow(configurator).to receive(:use)
      expect(job_wrapper.singleton_class).to receive(:prepend).with(Tracing::FlushSpansAfterJob)
      Tracing.configure
    end
  end

  describe Tracing::FlushSpansAfterJob do
    let(:tracer_provider) { instance_double(OpenTelemetry::SDK::Trace::TracerProvider) }
    let(:job_wrapper) do
      Class.new do
        def self.perform(job_data)
          raise 'job failed' if job_data == 'fail'
        end

        singleton_class.prepend Tracing::FlushSpansAfterJob
      end
    end

    before do
      require 'opentelemetry/sdk'
      allow(OpenTelemetry).to receive(:tracer_provider).and_return(tracer_provider)
    end

    it 'flushes spans after a job' do
      expect(tracer_provider).to receive(:force_flush)
      job_wrapper.perform('succeed')
    end

    it 'flushes spans after a job that fails' do
      expect(tracer_provider).to receive(:force_flush)
      expect { job_wrapper.perform('fail') }.to raise_error('job failed')
    end
  end
end
