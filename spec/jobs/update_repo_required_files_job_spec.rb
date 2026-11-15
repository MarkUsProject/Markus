describe UpdateRepoRequiredFilesJob do
  let(:assignment) { create(:assignment) }
  let(:user) { create(:instructor) }

  context 'when running as a background job' do
    let(:job_args) { [assignment.id] }

    it_behaves_like 'background job'
  end

  context 'when the assignment does not exist' do
    let(:job) { UpdateRepoRequiredFilesJob.new(-1) }

    it 'stores the error in the job status' do
      expect { job.perform_now }.to raise_error(ActiveRecord::RecordNotFound)
      expect(job.status.to_h).to include(
        status: :failed,
        exception: { class: 'ActiveRecord::RecordNotFound',
                     message: a_string_starting_with("Couldn't find Assignment with 'id'=-1") }
      )
    end
  end

  context 'updating required files' do
    include_context 'git'

    let!(:groupings) { create_list(:grouping, 3, assignment: assignment) }

    it 'should update every repo' do
      count = 0
      allow_any_instance_of(Repository::Transaction).to receive(:replace) { count += 1 }
      UpdateRepoRequiredFilesJob.perform_now(assignment.id)
      expect(count).to eq groupings.length
    end

    it 'should update the .required file' do
      allow_any_instance_of(Repository::Transaction).to receive(:replace) do |_txn, *args|
        expect(args[0]).to eq '.required'
      end
      UpdateRepoRequiredFilesJob.perform_now(assignment.id)
    end

    it 'should send the correct file content' do
      required_files = assignment.course.get_required_files
      allow_any_instance_of(Repository::Transaction).to receive(:replace) do |_txn, *args|
        expect(args[1]).to eq required_files
      end
      UpdateRepoRequiredFilesJob.perform_now(assignment.id)
    end
  end
end
