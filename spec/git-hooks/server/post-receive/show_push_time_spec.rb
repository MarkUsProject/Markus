describe '01-show_push_time.sh server git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { [] }
  let(:server_hooks) { ['01-show_push_time.sh'] }
  before { FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt')) }
  context 'when pushing to master' do
    it 'should not raise an error' do
      expect { push_changes }.not_to raise_error
    end
    it 'should report a message' do
      push_changes
      expect(server_hook_output.first).to include('Your submission has been received:')
    end
    it 'should report a timestamp that is about now' do
      push_changes
      delta = Time.current - Time.parse(server_hook_output.first.match(/master@{(.*)}/)[1]).getlocal
      expect(delta).to be < 3.seconds # should be enough time?
    end
  end
  context 'when pushing to a different branch' do
    before { Open3.capture3('git checkout -b other_branch', chdir: repo_path) }
    it 'should not raise an error' do
      expect { push_changes(upstream: 'other_branch') }.not_to raise_error
    end
    it 'should not report a message' do
      push_changes(upstream: 'other_branch')
      expect(server_hook_output.first).not_to include('Your submission has been received:')
    end
  end
end
