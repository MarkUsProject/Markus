describe 'pre-commit client git hook' do
  include_context 'git_hooks'
  context 'when not on the master branch' do
    before do
      dummy_hook = File.join(repo_path, '.git', 'hooks', 'pre-commit.d', '01-dummy.sh')
      File.write(dummy_hook, "#!/usr/bin/env sh\nexit 1") # dummy hook that will fail if run
      FileUtils.chmod 0o755, dummy_hook
      FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt'))
      Open3.capture3('git checkout -b other_branch', chdir: repo_path)
    end

    it 'should not run hooks when not on the master branch' do
      expect { commit_changes }.not_to raise_error
    end

    it 'should print a warning about skipping hooks' do
      commit_changes
      warning = "Skipping checks because you aren't on the master branch."
      expect(client_hook_output.first).to include(warning)
    end

    it 'should print a reminder that changes will not be graded' do
      commit_changes
      warning = 'But please remember that only files on your master branch will be graded!'
      expect(client_hook_output.first).to include(warning)
    end
  end
end
