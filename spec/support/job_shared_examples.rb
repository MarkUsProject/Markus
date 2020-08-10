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

def fake_exit_status(exit_code)
  fork { exit exit_code }
  Process.wait
  $CHILD_STATUS
end

shared_context 'autotest jobs' do
  let(:relative_url_root) { '/csc108' }
  let(:server_type) { 'local' }
  let(:data) { '' }
  let(:exit_code) { 0 }
  before :each do
    allow(Rails.application.config.action_controller).to receive(:relative_url_root).and_return(relative_url_root)
    if server_type == 'local'
      allow(Rails.configuration.x.autotest).to receive(:server_username).and_return(nil)
      allow(Open3).to receive(:capture2e).and_return([data, fake_exit_status(exit_code)])
      allow(Open3).to receive(:capture3).and_return(['', data, fake_exit_status(exit_code)])
    else
      allow(Rails.configuration.x.autotest).to receive(:server_username).and_return('autotst')
      status = Net::SSH::Connection::Session::StringWithExitstatus.new(data, exit_code)
      dummy_connection = instance_double('Net::SSH::Connection::Session')
      allow(dummy_connection).to receive(:exec!).and_return(status)
      allow(Net::SSH).to receive(:start) do |_, &block|
        block.call(dummy_connection)
      end
    end
  end
end

shared_examples 'shared autotest job tests' do |autotest_job_tests|
  include_context 'autotest jobs'
  context 'using a local autotesting server' do
    let(:server_type) { 'local' }
    context 'with a relative url root' do
      let(:relative_url_root) { '/csc108' }
      it_behaves_like autotest_job_tests
    end
    context 'without a relative url root' do
      let(:relative_url_root) { nil }
      it_behaves_like autotest_job_tests
    end
  end
  context 'using a remote autotesting server' do
    let(:server_type) { 'remote' }
    context 'with a relative url root' do
      let(:relative_url_root) { '/csc108' }
      it_behaves_like autotest_job_tests
    end
    context 'without a relative url root' do
      let(:relative_url_root) { nil }
      it_behaves_like autotest_job_tests
    end
  end
end
