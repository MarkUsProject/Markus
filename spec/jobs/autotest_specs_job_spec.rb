describe AutotestSpecsJob do
  let(:host_with_port) { 'http://localhost' }
  let(:assignment) { create :assignment }
  context 'when running as a background job' do
    let(:job_args) { [assignment, host_with_port] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now(assignment, host_with_port) }
  end
end
