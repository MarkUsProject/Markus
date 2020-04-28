describe UpdateStarterCodeJob do
  let(:assignment) { create :assignment }
  context 'when running as a background job' do
    let(:job_args) { [assignment.id, true] }
    include_examples 'background job'
  end

  context 'updating starter code' do
    shared_examples 'update starter code' do
      it 'should keep existing files' do
        assignment.each_group_repo do |repo|
          files = repo.get_latest_revision.files_at_path(assignment.repository_folder).keys
          expect(files).to include('starter_file1.txt')
        end
      end
      it 'should add new files' do
        assignment.each_group_repo do |repo|
          files = repo.get_latest_revision.files_at_path(assignment.repository_folder).keys
          expect(files).to include('starter_file2.txt')
        end
      end
    end
    let!(:groupings) { create_list :grouping, 3, assignment: assignment }
    before :each do
      assignment.access_starter_code_repo do |repo|
        txn = repo.get_transaction('test')
        txn.add(File.join(assignment.repository_folder, 'starter_file1.txt'), 'after')
        txn.add(File.join(assignment.repository_folder, 'starter_file2.txt'), 'after')
        repo.commit(txn)
      end
      assignment.each_group_repo do |repo|
        txn = repo.get_transaction('test')
        txn.add(File.join(assignment.repository_folder, 'starter_file1.txt'), 'before')
        repo.commit(txn)
      end
    end
    context 'when overwriting existing files' do
      before :each do
        UpdateStarterCodeJob.perform_now(assignment.id, true)
      end
      it_should_behave_like 'update starter code'
      it 'should overwrite existing starter code files' do
        assignment.each_group_repo do |repo|
          repo.get_latest_revision.files_at_path(assignment.repository_folder).each do |name, obj|
            if name == 'starter_file1.txt'
              expect(repo.stringify_files(obj)).to eq 'after'
            end
          end
        end
      end
    end
    context 'when not overwriting existing files' do
      before :each do
        UpdateStarterCodeJob.perform_now(assignment.id, false)
      end
      it_should_behave_like 'update starter code'
      it 'should not overwrite existing starter code files' do
        assignment.each_group_repo do |repo|
          repo.get_latest_revision.files_at_path(assignment.repository_folder).each do |name, obj|
            if name == 'starter_file1.txt'
              expect(repo.stringify_files(obj)).to eq 'before'
            end
          end
        end
      end
    end
  end
end
