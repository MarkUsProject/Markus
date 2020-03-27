shared_examples 'cancel test job' do
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
    it 'should not raise an error' do
      expect { subject }.to raise_error(RuntimeError, data)
    end
    it 'should not update time to service' do
      test_runs.each { |tr| tr.update(time_to_service: 10) }
      begin
        subject
      rescue RuntimeError
        # do nothing
      end
      expect(test_runs.each(&:reload).map(&:time_to_service)).not_to eq [-1, -1, -1]
    end
  end
end

describe AutotestCancelJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:test_runs) { create_list(:test_run, 3) }
  let(:test_run_ids) { test_runs.map(&:id) }
  context 'when running as a background job' do
    let(:job_args) { [host_with_port, test_run_ids] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now(host_with_port, test_run_ids) }
    include_context 'autotest jobs'
    context 'using a local autotesting server' do
      let(:server_type) { 'local' }
      context 'with a relative url root' do
        let(:relative_url_root) { '/csc108' }
        it_behaves_like 'cancel test job'
      end
    end
  end
end
