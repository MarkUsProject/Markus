describe UpdateStarterCodeJob do
  context 'when running as a background job' do
    let(:job_args) { [create(:assignment).id, true] }
    include_examples 'background job'
  end
end
