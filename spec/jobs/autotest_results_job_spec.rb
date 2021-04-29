describe AutotestResultsJob do
  let(:assignment) { create :assignment }
  before { Redis::Namespace.new(Rails.root.to_s).del('autotest_results') }
  context 'when running as a background job' do
    let(:job_args) { [assignment.id] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now }
  end
end
