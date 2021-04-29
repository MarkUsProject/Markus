shared_examples 'background job' do
  after :each do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  let(:job) { described_class.perform_later(*job_args) }

  it 'enqueues a job' do
    expect { job }.to have_enqueued_job
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
