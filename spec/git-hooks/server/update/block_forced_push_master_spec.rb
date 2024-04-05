describe '01-block_forced_push_master.sh server git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { [] }
  let(:server_hooks) { ['01-block_forced_push_master.sh'] }

  before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt')) }

  context 'when pushing to master' do
    context 'not force pushing' do
      before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt')) }

      it 'should not raise an error' do
        expect { push_changes }.not_to raise_error
      end

      it 'should not report a message' do
        push_changes
        expect(server_hook_output.first).not_to include('Error: forced push is not allowed on master!')
      end
    end

    context 'force pushing' do
      before do
        Open3.capture3('git reset --hard HEAD~1', chdir: repo_path) # something that requires a force push
      end

      it 'should raise an error' do
        expect { push_changes(force: true) }.to raise_error(RuntimeError)
      end

      it 'should report a message' do
        begin
          push_changes(force: true)
        rescue RuntimeError
          # do nothing
        end
        expect(server_hook_output.first).to include('Error: forced push is not allowed on master!')
      end
    end
  end

  context 'when pushing to a different branch' do
    before { Open3.capture3('git checkout -b other_branch', chdir: repo_path) }

    context 'not force pushing' do
      before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt')) }

      it 'should not raise an error' do
        expect { push_changes(upstream: 'other_branch') }.not_to raise_error
      end

      it 'should not report a message' do
        push_changes(upstream: 'other_branch')
        expect(server_hook_output.first).not_to include('Error: forced push is not allowed on master!')
      end
    end

    context 'force pushing' do
      before do
        Open3.capture3('git reset --hard HEAD~1', chdir: repo_path) # something that requires a force push
      end

      it 'should not raise an error' do
        expect { push_changes(force: true, upstream: 'other_branch') }.not_to raise_error
      end

      it 'should not report a message' do
        push_changes(force: true, upstream: 'other_branch')
        expect(server_hook_output.first).not_to include('Error: forced push is not allowed on master!')
      end
    end
  end
end
