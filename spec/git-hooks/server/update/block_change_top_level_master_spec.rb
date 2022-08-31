describe '02-block_change_top_level_master.sh server git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { [] }
  let(:server_hooks) { ['02-block_change_top_level_master.sh'] }
  it 'should not raise an error when adding a non-top level file' do
    FileUtils.touch(File.join(repo_path, 'A1', 'test.txt'))
    expect { push_changes }.not_to raise_error
  end
  context 'when an assignment file exists' do
    before :each do
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.add('A1/test.txt', 'something', 'text/plain')
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
    it 'should not raise an error when modifying the file' do
      File.write(File.join(repo_path, 'A1', 'test.txt'), 'something else')
      expect { push_changes }.not_to raise_error
    end
    it 'should not raise an error when deleting the file' do
      FileUtils.rm File.join(repo_path, 'A1', 'test.txt')
      expect { push_changes }.not_to raise_error
    end
  end
  it 'should raise an error when adding a top level file' do
    File.write(File.join(repo_path, 'test.txt'), 'something')
    expect { push_changes }.to raise_error(RuntimeError)
  end
  context 'when a top level file exists' do
    before :each do
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.add('test.txt', 'something', 'text/plain')
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
    it 'should raise an error when modifying the file' do
      File.write(File.join(repo_path, 'test.txt'), 'something else')
      expect { push_changes }.to raise_error(RuntimeError)
    end
    it 'should raise an error when deleting the file' do
      FileUtils.rm File.join(repo_path, 'test.txt')
      expect { push_changes }.to raise_error(RuntimeError)
    end
  end
  it 'should not raise an error when adding a top level .gitignore file' do
    File.write(File.join(repo_path, '.gitignore'), 'something')
    expect { push_changes }.not_to raise_error
  end
  context 'when a top level .gitignore file exists' do
    before :each do
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.add('.gitignore', 'something', 'text/plain')
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
    it 'should not raise an error when modifying the file' do
      File.write(File.join(repo_path, '.gitignore'), 'something else')
      expect { push_changes }.not_to raise_error
    end
    it 'should not raise an error when deleting the file' do
      FileUtils.rm File.join(repo_path, '.gitignore')
      expect { push_changes }.not_to raise_error
    end
  end
  context 'pushing to a different branch' do
    before { Open3.capture3('git checkout -b other_branch', chdir: repo_path) }
    it 'should not raise an error when adding a top level file' do
      File.write(File.join(repo_path, 'test.txt'), 'something')
      expect { push_changes(upstream: 'other_branch') }.not_to raise_error
    end
    context 'when a top level file exists' do
      before :each do
        GitRepository.access(repo.connect_string) do |open_repo|
          txn = open_repo.get_transaction('MarkUs')
          txn.add('test.txt', 'something', 'text/plain')
          raise txn.conflicts.join("\n") unless open_repo.commit(txn)
        end
      end
      it 'should raise an error when modifying the file' do
        File.write(File.join(repo_path, 'test.txt'), 'something else')
        expect { push_changes(upstream: 'other_branch') }.not_to raise_error
      end
      it 'should raise an error when deleting the file' do
        FileUtils.rm File.join(repo_path, 'test.txt')
        expect { push_changes(upstream: 'other_branch') }.not_to raise_error
      end
    end
  end
end
