describe '03-check_required_files_master.sh server git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { [] }
  let(:server_hooks) { ['03-check_required_files_master.sh'] }
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
        FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt'))
        expect { push_changes }.not_to raise_error
      end
    end

    context 'when updating a file' do
      before do
        GitRepository.access(repo.connect_string) do |open_repo|
          txn = open_repo.get_transaction('MarkUs')
          txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
          raise txn.conflicts.join("\n") unless open_repo.commit(txn)
        end
      end

      context 'by removing it' do
        it 'should not raise an error' do
          FileUtils.rm File.join(repo_path, assignment.repository_folder, 'test 1.txt')
          expect { push_changes }.not_to raise_error
        end
      end

      context 'by updating it' do
        it 'should not raise an error' do
          File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something else')
          expect { push_changes }.not_to raise_error
        end
      end
    end
  end

  context 'when there are required files' do
    include_context 'update_repo_with_required_files'
    context 'when only_required_files is false' do
      let(:required_files_attrs) do
        { only_required_files: false, assignment_files_attributes: [{ filename: 'test 1.txt' }] }
      end

      context 'when creating a required file' do
        before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt')) }

        it 'should not raise an error' do
          expect { push_changes }.not_to raise_error
        end

        it 'should not write a warning to stdout' do
          push_changes
          expect(server_hook_output.first).not_to include('Warning:')
        end
      end

      context 'when creating a non-required file' do
        before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'other.txt')) }

        it 'should not raise an error' do
          expect { push_changes }.not_to raise_error
        end

        it 'should write a warning to stdout' do
          push_changes
          warning = %r{Warning:\sYou\sare\ssubmitting\s#{assignment.repository_folder}/other\.txt\sbut\s
                       this\sassignment\sonly\srequires:(remote:|\s)*#{assignment.repository_folder}/test\s1\.txt}x
          expect(server_hook_output.first).to match(warning)
        end
      end

      context 'when modifying a required file' do
        before do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end

        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, assignment.repository_folder, 'test 1.txt') }

          it 'should not raise an error' do
            expect { push_changes }.not_to raise_error
          end

          it 'should write a warning to stdout' do
            push_changes
            warning = "Warning: You are deleting required file #{assignment.repository_folder}/test 1.txt."
            expect(server_hook_output.first).to include(warning)
          end
        end

        context 'by updating it' do
          before { File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something else') }

          it 'should not raise an error' do
            expect { push_changes }.not_to raise_error
          end

          it 'should not write a warning to stdout' do
            push_changes
            expect(server_hook_output.first).not_to include('Warning:')
          end
        end
      end

      context 'when modifying a non-required file' do
        before do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
            txn.add("#{assignment.repository_folder}/other.txt", 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end

        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, assignment.repository_folder, 'other.txt') }

          it 'should not raise an error' do
            expect { push_changes }.not_to raise_error
          end

          it 'should write a warning to stdout' do
            push_changes
            expect(server_hook_output.first).not_to include('Warning:')
          end
        end

        context 'by updating it' do
          before { File.write(File.join(repo_path, assignment.repository_folder, 'other.txt'), 'something else') }

          it 'should not raise an error' do
            expect { push_changes }.not_to raise_error
          end

          it 'should not write a warning to stdout' do
            push_changes
            expect(server_hook_output.first).not_to include('Warning:')
          end
        end
      end
    end

    context 'when only_required_files is true' do
      let(:required_files_attrs) do
        { only_required_files: true, assignment_files_attributes: [{ filename: 'test 1.txt' }] }
      end

      context 'when creating a required file' do
        before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt')) }

        it 'should not raise an error' do
          expect { push_changes }.not_to raise_error
        end

        it 'should not write a warning to stdout' do
          push_changes
          expect(server_hook_output.first).not_to include('Warning:')
        end
      end

      context 'when creating a non-required file' do
        before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'other.txt')) }

        it 'should raise an error' do
          expect { push_changes }.to raise_error(RuntimeError)
        end

        it 'should write an error to stdout' do
          begin
            push_changes
          rescue RuntimeError
            # do nothing
          end
          error = %r{Error:\sYou\sare\ssubmitting\s#{assignment.repository_folder}/other\.txt\sbut\sthis\s
                     assignment\sonly\srequires:(remote:|\s)*#{assignment.repository_folder}/test\s1\.txt}x
          expect(server_hook_output.first).to match(error)
        end

        context 'on a different branch' do
          before { Open3.capture3('git checkout -b other_branch', chdir: repo_path) }

          it 'should not raise an error' do
            expect { push_changes(upstream: 'other_branch') }.not_to raise_error
          end

          it 'should not write an error or warning to stdout' do
            push_changes(upstream: 'other_branch')
            expect(server_hook_output.first).not_to include('Error:')
            expect(server_hook_output.first).not_to include('Warning:')
          end
        end
      end

      context 'when modifying a required file' do
        before do
          GitRepository.access(repo.connect_string) do |open_repo|
            txn = open_repo.get_transaction('MarkUs')
            txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
            raise txn.conflicts.join("\n") unless open_repo.commit(txn)
          end
        end

        context 'by removing it' do
          before { FileUtils.rm File.join(repo_path, assignment.repository_folder, 'test 1.txt') }

          it 'should not raise an error' do
            expect { push_changes }.not_to raise_error
          end

          it 'should write a warning to stdout' do
            push_changes
            warning = "Warning: You are deleting required file #{assignment.repository_folder}/test 1.txt."
            expect(server_hook_output.first).to include(warning)
          end
        end

        context 'by updating it' do
          before { File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something else') }

          it 'should not raise an error' do
            expect { push_changes }.not_to raise_error
          end

          it 'should not write a warning to stdout' do
            push_changes
            expect(server_hook_output.first).not_to include('Warning:')
          end
        end
      end

      context 'when modifying a non-required file' do
        context 'for the current assignment' do
          before do
            GitRepository.access(repo.connect_string) do |open_repo|
              txn = open_repo.get_transaction('MarkUs')
              txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
              txn.add("#{assignment.repository_folder}/other.txt", 'something', 'text/plain')
              raise txn.conflicts.join("\n") unless open_repo.commit(txn)
            end
          end

          context 'by removing it' do
            before { FileUtils.rm File.join(repo_path, assignment.repository_folder, 'other.txt') }

            it 'should not raise an error' do
              expect { push_changes }.not_to raise_error
            end

            it 'should write a warning to stdout' do
              push_changes
              expect(server_hook_output.first).not_to include('Warning:')
            end
          end

          context 'by updating it' do
            before { File.write(File.join(repo_path, assignment.repository_folder, 'other.txt'), 'something else') }

            it 'should not raise an error' do
              expect { push_changes }.not_to raise_error
            end

            it 'should write a warning to stdout' do
              push_changes
              warning = %r{Warning:\sYou\sare\smodifying\snon-required\sfile\s#{assignment.repository_folder}/
                           other\.txt\sbut\sthis\sassignment\sonly\srequires:(remote:|\s)*
                           #{assignment.repository_folder}/test\s1\.txt}x
              expect(server_hook_output.first).to match(warning)
            end
          end
        end

        context 'for a different assignment' do
          let(:assignment2) { create(:assignment, course: course) }

          before do
            GitRepository.access(repo.connect_string) do |open_repo|
              txn = open_repo.get_transaction('MarkUs')
              txn.add("#{assignment2.repository_folder}/test 1.txt", 'something', 'text/plain')
              txn.add("#{assignment2.repository_folder}/other.txt", 'something', 'text/plain')
              raise txn.conflicts.join("\n") unless open_repo.commit(txn)
            end
          end

          context 'by removing it' do
            before { FileUtils.rm File.join(repo_path, assignment2.repository_folder, 'other.txt') }

            it 'should not raise an error' do
              expect { push_changes }.not_to raise_error
            end

            it 'should write a warning to stdout' do
              push_changes
              expect(server_hook_output.first).not_to include('Warning:')
            end
          end

          context 'by updating it' do
            before { File.write(File.join(repo_path, assignment2.repository_folder, 'other.txt'), 'something else') }

            it 'should not raise an error' do
              expect { push_changes }.not_to raise_error
            end

            it 'should write a warning to stdout' do
              push_changes
              expect(server_hook_output.first).not_to include('Warning:')
            end
          end
        end
      end
    end
  end
end
