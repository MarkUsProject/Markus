describe SubmissionsJob do
  context 'when running as a background job' do
    let(:job_args) { [create_list(:grouping, 3)] }
    include_examples 'background job'
  end
end
