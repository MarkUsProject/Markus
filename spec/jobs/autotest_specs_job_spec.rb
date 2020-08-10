shared_examples 'run specs job' do
  subject { described_class.perform_now(host_with_port, assignment) }
  context 'when the cancelation is performed without errors' do
    let(:data) { '' }
    let(:exit_code) { 0 }
    it 'should not raise an error' do
      subject
    end
  end
  context 'when the cancelation is performed with errors' do
    let(:data) { 'some problem happened' }
    let(:exit_code) { 1 }
    it 'should raise an error with the process output' do
      expect { subject }.to raise_error(RuntimeError, data)
    end
  end
end

describe AutotestSpecsJob do
  let(:host_with_port) { 'http://localhost' }
  let(:assignment) { create :assignment }
  context 'when running as a background job' do
    let(:job_args) { [host_with_port, assignment] }
    include_examples 'background job'
  end
  it_behaves_like 'shared autotest job tests', 'run specs job'
end
