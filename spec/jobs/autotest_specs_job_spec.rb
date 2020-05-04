shared_examples 'run specs job' do
  subject { described_class.perform_now(host_with_port, assignment) }
  # TODO: add tests for sending the scripts and the test run job to the server OR
  #       reconfigure the autotester so that files don't need to be sent (whichever comes first)
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
