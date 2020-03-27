describe GenerateJob do
  context 'when running as a background job' do
    let(:job_args) { [create(:exam_template_midterm), 2, true] }
    include_examples 'background job'
  end
end
