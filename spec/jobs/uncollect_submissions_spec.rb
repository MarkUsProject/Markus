describe UncollectSubmissions do
  context 'when running as a background job' do
    let(:job_args) { [create(:assignment)] }

    include_examples 'background job'
  end
end
