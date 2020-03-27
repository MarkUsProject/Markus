describe UpdateRepoRequiredFilesJob do
  context 'when running as a background job' do
    let(:job_args) { [create(:assignment).id, create(:admin).user_name] }
    include_examples 'background job'
  end
end
