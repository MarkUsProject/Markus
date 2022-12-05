describe GitRevision do
  context 'with a git repo' do
    let(:repo) { build(:git_repository) }
    before(:each) { FileUtils.rm_r(Dir.glob(File.join(Repository.root_dir, '*'))) }
    describe '#files_at_path' do
      # Commit a file named test in the workdir
      before(:each) do
        transaction = repo.get_transaction('dummy') # dummy user_id

        transaction.add('test', 'testdata')
        repo.commit(transaction)
      end
      it 'retrieves an object with the same name from the repo' do
        # Get latest revision's file in the working directory
        revision = repo.get_latest_revision
        files = revision.files_at_path('')

        expect(files).to include 'test'
      end
      it 'retrieves an object of type Repository::RevisionFile' do
        revision = repo.get_latest_revision
        files = revision.files_at_path('')
        test_file = files['test']
        # It should be the right type
        expect(test_file).to be_a Repository::RevisionFile
      end
      # retrieves objects not in the workdir
    end
    describe '#directories_at_path' do
      before(:each) do
        # Commit a file named test2 in a folder called testdir
        transaction = repo.get_transaction('dummy') # dummy user_id

        transaction.add('testdir/test', 'testdata')
        repo.commit(transaction)
      end
      it 'retrieves an object with the same name from the repo' do
        revision = repo.get_latest_revision
        directories = revision.directories_at_path('')
        expect(directories).to include 'testdir'
      end
      it 'retrieves an object of type Repository::RevisionDirectory' do
        revision = repo.get_latest_revision
        directories = revision.directories_at_path('')
        test_dir = directories['testdir']

        expect(test_dir).to be_a Repository::RevisionDirectory
      end
    end

    describe '#stringify' do
      before(:each) do
        transaction = repo.get_transaction('dummy') # dummy user_id

        transaction.add('test', 'testdata')
        repo.commit(transaction)
      end
      it 'gets the correct file data' do
        revision = repo.get_latest_revision
        files = revision.files_at_path('')
        test_file = files['test']

        expect(repo.stringify(test_file)).to eq 'testdata'
      end
    end
  end
end
