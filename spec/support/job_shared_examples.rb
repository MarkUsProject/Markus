shared_examples 'background job' do
  before do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  let(:job) { described_class.perform_later(*job_args) }

  it 'enqueues a job' do
    expect { job }.to have_enqueued_job(described_class)
  end

  it 'adds the job_class to status' do
    expect(job.status[:job_class]).to eq(described_class)
  end

  xit 'stores the error message' do
    # TODO: add a test that checks if the error message is stored in the job
    #       status when an error is raised in the test. I am currently unaware
    #       of a way to check this in a test environment.
  end
end

shared_examples 'autotest jobs' do
  xcontext 'and the rate limit has been hit' do
    # TODO: callbacks are not called when calling perform_now. Figure out a better way to test this
    before do
      allow_any_instance_of(described_class).to receive(:send_request).and_raise(
        AutomatedTestsHelper::AutotestApi::LimitExceededException
      )
    end

    it 'reschedules the job one minute later' do
      expect(described_class).to receive(:set).with(wait: 1.minute).once.and_call_original
      expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).once
      subject
    end
  end
end
