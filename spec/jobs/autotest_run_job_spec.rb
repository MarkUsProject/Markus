shared_examples 'run test job' do
  subject { described_class.perform_now(host_with_port, user.id, assignment.id, test_run_info_created) }
  context 'when the enqueuing is performed without errors' do
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
      subject
      test_run_info_created.each do |test_run|
        expect(TestRun.find(test_run[:id]).problems).to include(data)
      end
    end
  end
end

describe AutotestRunJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:assignment) { create(:assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:test_runs) { create_list(:test_run, 3, grouping: grouping) }
  let(:user) { create(:admin) }
  let(:test_run_info_created) { test_runs.map { |tr| { id: tr[:id] } } }
  let(:test_run_info_not_created) do
    groupings = create_list(:grouping_with_inviter_and_submission, 3, assignment: assignment)
    groupings.map(&:reload).map { |g| { grouping_id: g.id, submission_id: g.current_submission_used.id } }
  end
  context 'when running as a background job' do
    let(:job_args) { [host_with_port, user.id, assignment.id, test_run_info_created] }
    include_examples 'background job'
  end
  describe '#perform' do
    context 'when the test runs are not created yet' do
      before :each do
        allow_any_instance_of(AutotestRunJob).to receive(:enqueue_test_run)
        allow(Net::SSH).to receive(:start)
      end
      subject { described_class.perform_now(host_with_port, user.id, assignment.id, test_run_info_not_created) }
      it 'should create new test runs' do
        expect { subject }.to change { TestRun.count }.from(0).to(3)
      end
      it 'should create new test runs with the correct values' do
        subject
        test_run_info_not_created.each do |h|
          expect(TestRun.find_by(h)).not_to be_nil
        end
      end
      it 'should create a new batch if there are multiple runs' do
        expect { subject }.to change { TestBatch.count }.from(0).to(1)
      end
      it 'should not create a new batch if there is only one run' do
        args = [host_with_port, user.id, assignment.id, test_run_info_not_created[0...1]]
        expect { described_class.perform_now(*args) }.not_to(change { TestBatch.count })
      end
    end
    it_behaves_like 'shared autotest job tests', 'run test job'
  end
end
