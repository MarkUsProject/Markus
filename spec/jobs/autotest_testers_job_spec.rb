describe AutotestTestersJob do
  context 'when running as a background job' do
    let(:job_args) { [] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now }
  end
end
