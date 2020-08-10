describe UpdateRepoRequiredFilesJob do
  let(:assignment) { create :assignment }
  let(:user) { create :admin }
  context 'when running as a background job' do
    let(:job_args) { [assignment.id, user.user_name] }
    include_examples 'background job'
  end

  context 'updating required files' do
    # TODO: when we update tests to use in-memory git repos, actually test for presence/content of .required.json
    let!(:groupings) { create_list :grouping, 3, assignment: assignment }
    it 'should update every repo' do
      count = 0
      allow_any_instance_of(Repository::Transaction).to receive(:replace) { count += 1 }
      UpdateRepoRequiredFilesJob.perform_now(assignment.id, user.user_name)
      expect(count).to eq groupings.length
    end
    it 'should update the .required.json file' do
      allow_any_instance_of(Repository::Transaction).to receive(:replace) do |_txn, *args|
        expect(args[0]).to eq '.required.json'
      end
      UpdateRepoRequiredFilesJob.perform_now(assignment.id, user.user_name)
    end
    it 'should send the correct file content' do
      required_files = Assignment.get_required_files.stringify_keys.transform_values(&:stringify_keys)
      allow_any_instance_of(Repository::Transaction).to receive(:replace) do |_txn, *args|
        expect(JSON.parse(args[1])).to eq required_files
      end
      UpdateRepoRequiredFilesJob.perform_now(assignment.id, user.user_name)
    end
  end
end
