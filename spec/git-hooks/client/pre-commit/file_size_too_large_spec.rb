describe '04-file_size_too_large.sh client git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { ['04-file_size_too_large.sh'] }
  shared_context 'update_repo_with_max_file_size' do
    before do
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.replace('.max_file_size',
                    max_file_size.to_s,
                    'text/plain',
                    repo.get_latest_revision.revision_identifier)
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
  end
  context 'when the changed file is not larger than the max_file_size' do
    context 'when adding a file' do
      it 'should not raise an error' do
        FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt'))
        expect { commit_changes }.not_to raise_error
      end
    end
    context 'when updating a file' do
      before :each do
        GitRepository.access(repo.connect_string) do |open_repo|
          txn = open_repo.get_transaction('MarkUs')
          txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
          raise txn.conflicts.join("\n") unless open_repo.commit(txn)
        end
      end
      context 'by removing it' do
        it 'should not raise an error' do
          FileUtils.rm File.join(repo_path, assignment.repository_folder, 'test 1.txt')
          expect { commit_changes }.not_to raise_error
        end
      end
      context 'by updating it' do
        it 'should not raise an error' do
          File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something else')
          expect { commit_changes }.not_to raise_error
        end
      end
    end
  end
  context 'when the changed file is larger than the max_file_size' do
    let(:max_file_size) { 1 }
    include_context 'update_repo_with_max_file_size'
    context 'when adding a file' do
      before { File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something') }
      it 'should raise an error' do
        expect { commit_changes }.to raise_error(RuntimeError)
      end
      it 'should print an error' do
        begin
          commit_changes
        rescue RuntimeError
          # do nothing
        end
        error = "Error: The size of the modified file #{assignment.repository_folder}/test 1.txt " \
                'exceeds the maximum of 1 bytes'
        expect(client_hook_output.first).to include(error)
      end
    end
    context 'when updating a file' do
      before :each do
        GitRepository.access(repo.connect_string) do |open_repo|
          txn = open_repo.get_transaction('MarkUs')
          txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
          raise txn.conflicts.join("\n") unless open_repo.commit(txn)
        end
      end
      context 'by removing it' do
        it 'should not raise an error' do
          FileUtils.rm File.join(repo_path, assignment.repository_folder, 'test 1.txt')
          expect { commit_changes }.not_to raise_error
        end
      end
      context 'by updating it' do
        before { File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something else') }
        it 'should raise an error' do
          expect { commit_changes }.to raise_error(RuntimeError)
        end
        it 'should print an error' do
          begin
            commit_changes
          rescue RuntimeError
            # do nothing
          end
          error = "Error: The size of the modified file #{assignment.repository_folder}/test 1.txt " \
                  'exceeds the maximum of 1 bytes'
          expect(client_hook_output.first).to include(error)
        end
      end
    end
  end
end
