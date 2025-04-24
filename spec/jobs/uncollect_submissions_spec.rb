describe UncollectSubmissions do
  context 'when running as a background job' do
    let(:job_args) { [create(:assignment)] }

    it_behaves_like 'background job'
  end
end
