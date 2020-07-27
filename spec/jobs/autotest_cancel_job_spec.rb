shared_examples 'cancel test job' do
  subject { described_class.perform_now(host_with_port, assignment.id, test_run_ids) }
  context 'when the cancelation is performed without errors' do
    let(:data) { '' }
    let(:exit_code) { 0 }
    it 'should not raise an error' do
      subject
    end
    it 'should update time to service' do
      test_runs.each { |tr| tr.update(time_to_service: 10) }
      subject
      expect(test_runs.each(&:reload).map(&:time_to_service)).to eq [-1, -1, -1]
    end
  end
  context 'when the cancelation is performed with errors' do
    let(:data) { 'some problem happened' }
    let(:exit_code) { 1 }
    it 'should raise an error with the process output' do
      expect { subject }.to raise_error(RuntimeError, data)
    end
    it 'should not update time to service' do
      test_runs.each { |tr| tr.update(time_to_service: 10) }
      expect { subject }.to raise_error(RuntimeError)
      expect(test_runs.each(&:reload).map(&:time_to_service)).not_to eq [-1, -1, -1]
    end
  end
end

describe AutotestCancelJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:assignment) { create(:assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:test_runs) { create_list(:test_run, 3, grouping: grouping) }
  let(:test_run_ids) { test_runs.map(&:id) }
  context 'when running as a background job' do
    let(:job_args) { [host_with_port, test_run_ids] }
    include_examples 'background job'
  end
  describe '#perform' do
    it_behaves_like 'shared autotest job tests', 'cancel test job'
  end
end
