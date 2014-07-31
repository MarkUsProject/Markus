require 'spec_helper'
describe Repository::GitRevision do
  context 'with a repo' do
    # Set up git creation config...
    config = {}
    config['REPOSITORY_STORAGE'] = '#{::Rails.root}/data/test/repos/test_repo'
    config['REPOSITORY_PERMISSION_FILE'] = REPOSITORY_STORAGE + '/conf'
    config['IS_REPOSITORY_ADMIN'] = true

    # Actually create the repo...
    repo = Repository.get_class('git', config)
    repo.create(config['REPOSITORY_STORAGE'])
    repo = repo.new(config['REPOSITORY_STORAGE'])

    describe '#files_at_path' do
      # Commit a file name test in the workdir
      transaction = repo.get_transaction(0) # dummy user_id
      transaction.add('test', 'testdata')
      repo.commit(transaction)

      it 'should retrieve an object with the same name from the repo' do
        # Get latest revision's file in the working directory
        revision = repo.get_latest_revision
        files = revision.files_at_path('')

        expect(files).to include('test')
      end

      it 'should retrieve an object of type Repository::RevisionFile' do
        revision = repo.get_latest_revision
        files = revision.files_at_path('')
        test_file = files['test']

        # It should be the right type
        expect(test_file).to be_a(Repository::RevisionFile)
      end
    end

    describe '#directories_at_path' do
      # Commit a file named test2 in a folder called testdir
      transaction = repo.get_transaction(0) # dummy user_id
      transaction.add('testdir/test2', 'testdata')
      repo.commit(transaction)

      it 'should retrieve an object with the same name from the repo' do
        revision = repo.get_latest_revision
        directories = revision.directories_at_path('')
        expect(directories).to include('testdir')
      end

      it 'should retrieve an object of type Repository::RevisionDirectory' do
        revision = repo.get_latest_revision
        directories = revision.directories_at_path('')
        test_dir = directories['testdir']

        expect(test_dir).to be_a(Repository::RevisionDirectory)
      end
    end

    describe '#stringify' do
      it 'should get the correct file data' do
        revision = repo.get_latest_revision
        files = revision.files_at_path('')
        test_file = files['test']

        expect(repo.stringify(test_file)).to eq('testdata')

      end
    end
  end
end
