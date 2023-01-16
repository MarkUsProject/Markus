shared_context 'git' do
  before do
    allow(Settings.repository).to receive(:type).and_return('git')
    allow(Repository.get_class).to receive(:purge_all).and_return nil
  end
  after { FileUtils.rm_r(Dir.glob(File.join(Repository.root_dir, '*'))) }
end

shared_context 'git_hooks' do
  let!(:course) { create :course }
  let!(:assignment) { create :assignment, course: course }
  let(:repo) { build(:git_repository) }
  let(:repo_path) { repo.tmp_repo }
  let(:repo_bare_path) { repo.get_repos_path }
  let(:client_hooks) { false }
  let(:server_hooks) { false }
  let(:client_hook_output) { [] }
  let(:server_hook_output) { [] }
  before :each do
    FileUtils.rm_rf(File.join(repo_path, '.git', 'hooks'))
    FileUtils.cp_r(File.join(repo_path, 'markus-hooks'), File.join(repo_path, '.git', 'hooks'))
    if client_hooks
      Dir.glob(File.join(repo_path, '.git', 'hooks', '*', '*')).each do |hook_path|
        File.write(hook_path, "#!/usr/bin/env sh\nexit 0") unless client_hooks.include?(File.basename(hook_path))
      end
    end
    if server_hooks
      Dir.glob(File.join(repo_bare_path, 'hooks', '*', '*')).each do |hook_path|
        File.write(hook_path, "#!/usr/bin/env sh\nexit 0") unless server_hooks.include?(File.basename(hook_path))
      end
    end
    txn = repo.get_transaction('MarkUs')
    course.assignments.pluck(:repository_folder).each do |repo_folder|
      txn.add_path(repo_folder)
    end
    repo.commit(txn)
  end
  after :each do
    FileUtils.rm_r(repo_path)
    FileUtils.rm_r(repo_bare_path)
  end
  def commit_changes(changes: '.')
    remotes = Open3.popen3('git remote -v', chdir: repo_path)[1].read.lines.map { |line| line.split[...2] }.to_h
    unless File.realpath(remotes['origin']) == File.realpath(repo_bare_path)
      # This is to ensure that the test isn't accidentally committing to the MarkUs repo
      raise 'ERROR: the repo under test is not a test repo'
    end

    Open3.capture2('git config user.email test@example.com', chdir: repo_path)
    Open3.capture2('git config user.name test', chdir: repo_path)
    Open3.capture2("git add #{changes}", chdir: repo_path)

    Open3.popen2e('git commit -m "test"', chdir: repo_path) do |_stdin, out_err, wait_thr|
      output = out_err.read
      client_hook_output << output
      raise output unless wait_thr.value.success?
    end
  end

  def push_changes(force: false, upstream: 'master')
    commit_changes
    cmd = "git push #{force ? '--force' : ''} --set-upstream origin #{upstream}"
    Open3.popen2e({ 'SKIP_LOCAL_GIT_HOOKS' => '' }, cmd, chdir: repo_path) do |_stdin, out_err, wait_thr|
      output = out_err.read
      server_hook_output << output
      raise output unless wait_thr.value.success?
    end
  end
end
