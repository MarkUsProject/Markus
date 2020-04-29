shared_examples 'run testers job' do
  subject { described_class.perform_now }
  # TODO: add tests for sending the scripts and the test run job to the server OR
  #       reconfigure the autotester so that files don't need to be sent (whichever comes first)
end

describe AutotestTestersJob do
  context 'when running as a background job' do
    let(:job_args) { [] }
    include_examples 'background job'
  end
  it_behaves_like 'shared autotest job tests', 'run testers job'
end
