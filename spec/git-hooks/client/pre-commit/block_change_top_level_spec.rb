describe '02-block_change_top_level.sh client git hook' do
  include_context 'git_hooks'
  let(:client_hooks) { ['02-block_change_top_level.sh'] }
  it 'should not raise an error when adding a non-top level file' do
    FileUtils.touch(File.join(repo_path, assignment.repository_folder, 'test 1.txt'))
    expect { commit_changes }.not_to raise_error
  end
  context 'when an assignment file exists' do
    before :each do
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.add("#{assignment.repository_folder}/test 1.txt", 'something', 'text/plain')
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
    it 'should not raise an error when modifying the file' do
      File.write(File.join(repo_path, assignment.repository_folder, 'test 1.txt'), 'something else')
      expect { commit_changes }.not_to raise_error
    end
    it 'should not raise an error when deleting the file' do
      FileUtils.rm File.join(repo_path, assignment.repository_folder, 'test 1.txt')
      expect { commit_changes }.not_to raise_error
    end
  end
  it 'should raise an error when adding a top level file' do
    File.write(File.join(repo_path, 'test 1.txt'), 'something')
    expect { commit_changes }.to raise_error(RuntimeError)
  end
  it 'should raise and error when adding a top level directory' do
    FileUtils.mkdir_p(File.join(repo_path, 'test'))
    File.write(File.join(repo_path, 'test', 'test 1.txt'), 'something')
    expect { commit_changes }.to raise_error(RuntimeError)
  end
  context 'when a top level file exists' do
    before :each do
      GitRepository.access(repo.connect_string) do |open_repo|
        txn = open_repo.get_transaction('MarkUs')
        txn.add('test 1.txt', 'something', 'text/plain')
        raise txn.conflicts.join("\n") unless open_repo.commit(txn)
      end
    end
    it 'should raise an error when modifying the file' do
      File.write(File.join(repo_path, 'test 1.txt'), 'something else')
      expect { commit_changes }.to raise_error(RuntimeError)
    end
    it 'should raise an error when deleting the file' do
      FileUtils.rm File.join(repo_path, 'test 1.txt')
      expect { commit_changes }.to raise_error(RuntimeError)
    end
  end
  it 'should not raise an error when adding a top level .gitignore file' do
    File.write(File.join(repo_path, '.gitignore'), 'something')
    expect { commit_changes }.not_to raise_error
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
      expect { commit_changes }.not_to raise_error
    end
    it 'should not raise an error when deleting the file' do
      FileUtils.rm File.join(repo_path, '.gitignore')
      expect { commit_changes }.not_to raise_error
    end
  end
end
