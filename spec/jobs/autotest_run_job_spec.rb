describe AutotestRunJob do
  context 'when running as a background job' do
    let(:job_args) { ['http://localhost', create(:admin), [1, 2]] }
    include_examples 'background job'
  end
end
