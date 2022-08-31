describe '03-check_required_files.sh client git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { ['03-check_required_files.sh'] }
  let(:assignment) { create :assignment, short_identifier: 'A1' }
  let(:required_files_attrs) { {} }
  shared_context 'update_repo_with_required_files' do
    before do
      assignment.update!(required_files_attrs)
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.replace('.required',
                    course.reload.get_required_files,
                    'text/plain',
                    repo.get_latest_revision.revision_identifier)
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
  end
  context 'when there are no required files' do
    context 'when adding a file' do
      it 'should not raise an error' do
        FileUtils.touch(File.join(repo_path, 'A1', 'test.txt'))
        expect { commit_changes }.not_to raise_error
      end
    end
    context 'when updating a file' do
      before :each do
        GitRepository.access(repo.connect_string) do |open_repo|
          txn = open_repo.get_transaction('MarkUs')
          txn.add('A1/test.txt', 'something', 'text/plain')
          raise txn.conflicts.join("\n") unless open_repo.commit(txn)
        end
      end
      context 'by removing it' do
        it 'should not raise an error' do
          FileUtils.rm File.join(repo_path, 'A1', 'test.txt')
          expect { commit_changes }.not_to raise_error
        end
      end
      context 'by updating it' do
        it 'should not raise an error' do
          File.write(File.join(repo_path, 'A1', 'test.txt'), 'something else')
          expect { commit_changes }.not_to raise_error
        end
      end
    end
  end
  context 'when there are required files' do
    include_context 'update_repo_with_required_files'
    context 'when only_required_files is false' do
      let(:required_files_attrs) do
        { only_required_files: false, assignment_files_attributes: [{ filename: 'test.txt' }] }
      end
      context 'when creating a required file' do
        before { FileUtils.touch(File.join(repo_path, 'A1', 'test.txt')) }
        it 'should not raise an error' do
          expect { commit_changes }.not_to raise_error
        end
        it 'should not write a warning to stdout' do
          commit_changes
          expect(client_hook_output.first).not_to include('Warning:')
        end
      end
      context 'when creating a non-required file' do
        before { FileUtils.touch(File.join(repo_path, 'A1', 'other.txt')) }
        it 'should not raise an error' do
          expect { commit_changes }.not_to raise_error
        end
        it 'should write a warning to stdout' do
          commit_changes
          warning = "Warning: You are submitting A1/other.txt but this assignment only requires:\n\nA1/test.txt"
          expect(client_hook_output.first).to include(warning)
        end
      end
      context 'when modifying a required file' do
        before :each do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add('A1/test.txt', 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end
        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, 'A1', 'test.txt') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).to include('Warning: You are deleting required file A1/test.txt.')
          end
        end
        context 'by updating it' do
          before { File.write(File.join(repo_path, 'A1', 'test.txt'), 'something else') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should not write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).not_to include('Warning:')
          end
        end
      end
      context 'when modifying a non-required file' do
        before :each do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add('A1/test.txt', 'something', 'text/plain')
            txn.add('A1/other.txt', 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end
        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, 'A1', 'other.txt') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).not_to include('Warning:')
          end
        end
        context 'by updating it' do
          before { File.write(File.join(repo_path, 'A1', 'other.txt'), 'something else') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should not write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).not_to include('Warning:')
          end
        end
      end
    end
    context 'when only_required_files is true' do
      let(:required_files_attrs) do
        { only_required_files: true, assignment_files_attributes: [{ filename: 'test.txt' }] }
      end
      context 'when creating a required file' do
        before { FileUtils.touch(File.join(repo_path, 'A1', 'test.txt')) }
        it 'should not raise an error' do
          expect { commit_changes }.not_to raise_error
        end
        it 'should not write a warning to stdout' do
          commit_changes
          expect(client_hook_output.first).not_to include('Warning:')
        end
      end
      context 'when creating a non-required file' do
        before { FileUtils.touch(File.join(repo_path, 'A1', 'other.txt')) }
        it 'should raise an error' do
          expect { commit_changes }.to raise_error(RuntimeError)
        end
        it 'should write an error to stdout' do
          begin
            commit_changes
          rescue RuntimeError
            # do nothing
          end
          error = "Error: You are submitting A1/other.txt but this assignment only requires:\n\nA1/test.txt"
          expect(client_hook_output.first).to include(error)
        end
      end
      context 'when modifying a required file' do
        before :each do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add('A1/test.txt', 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end
        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, 'A1', 'test.txt') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).to include('Warning: You are deleting required file A1/test.txt.')
          end
        end
        context 'by updating it' do
          before { File.write(File.join(repo_path, 'A1', 'test.txt'), 'something else') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should not write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).not_to include('Warning:')
          end
        end
      end
      context 'when modifying a non-required file' do
        before :each do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add('A1/test.txt', 'something', 'text/plain')
            txn.add('A1/other.txt', 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end
        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, 'A1', 'other.txt') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should write a warning to stdout' do
            commit_changes
            expect(client_hook_output.first).not_to include('Warning:')
          end
        end
        context 'by updating it' do
          before { File.write(File.join(repo_path, 'A1', 'other.txt'), 'something else') }
          it 'should not raise an error' do
            expect { commit_changes }.not_to raise_error
          end
          it 'should write a warning to stdout' do
            commit_changes
            warning = 'Warning: You are modifying non-required file A1/other.txt but this assignment only requires:' \
                      "\n\nA1/test.txt"
            expect(client_hook_output.first).to include(warning)
          end
        end
      end
    end
  end
end
