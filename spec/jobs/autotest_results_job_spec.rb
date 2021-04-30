describe AutotestResultsJob do
  let(:assignment) { create :assignment }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let!(:test_runs) { create_list(:test_run, 3, grouping: grouping, status: :in_progress) }
  context 'when running as a background job' do
    let(:job_args) { [assignment.id] }
    context 'if there is no job currently in progress' do
      before { Redis::Namespace.new(Rails.root.to_s).del('autotest_results') }
      include_examples 'background job'
    end
    context 'if there is a job currently in progress' do
      before do
        Redis::Namespace.new(Rails.root.to_s).set('autotest_results', 1)
        clear_enqueued_jobs
        clear_performed_jobs
      end
      after do
        clear_enqueued_jobs
        clear_performed_jobs
      end
      let(:job) { described_class.perform_later(*job_args) }

      it 'enqueues a job' do
        expect { job }.not_to have_enqueued_job
      end
    end
  end
  describe '#perform' do
    before { Redis::Namespace.new(Rails.root.to_s).del('autotest_results') }
    subject { described_class.perform_now }
    context 'tests are set up for an assignment' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { autotest_settings_id: 10 } }
    end
    context 'tests are not set up' do
      it 'should try again with reduced retries' do
        expect(AutotestResultsJob).to receive(:set).with(wait: 1.minute).once.and_call_original
        expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).with(_retry: 2).once
        subject
      end
    end
  end
end
