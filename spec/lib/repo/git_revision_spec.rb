require 'spec_helper'

describe Repository::GitRevision do
  context 'with a git repo' do
    before(:context) do
      
     
      
      # Make sure gitolite-admin repo is cloned in test environment
      ga_repo = Gitolite::GitoliteAdmin.new(
        "#{::Rails.root}/data/test/repos/gitolite-admin", GITOLITE_SETTINGS)

      puts 123
      puts GITOLITE_SETTINGS
      
      # Bring the repo up to date
      ga_repo.reload!

      # Grab the gitolite admin repo config
      conf = ga_repo.config

      # Remove test repo from Gitolite conf
      conf.rm_repo('test_repo')

      # Make sure repo was deleted, then remake it
      repo = ga_repo.config.get_repo('test_repo')
      if !repo.nil?
        raise 'Gitolite failed to delete the test_repo before test context!'
      end

      # Generate new test repo
      repo = Gitolite::Config::Repo.new('test_repo')

      # Add permissions for git user
      repo.add_permission('RW+', '', 'git')

      # Add the repo to the gitolite admin config
      conf.add_repo(repo)

      # Readd the 'git' public key to the gitolite admin repo after changes
      admin_key = Gitolite::SSHKey.from_file(
        GITOLITE_SETTINGS[:public_key])
      ga_repo.add_key(admin_key)

      # Stage and push the changes to the gitolite admin repo
      ga_repo.save_and_apply

      # Remove workdir (cloned version of the test_repo from Gitolite)
      FileUtils.rm_rf("#{::Rails.root}/data/test/workdir")

      # Repo is created by gitolite, proceed to clone it in
      # the repository storage location
      Git.clone('git@localhost:' + "test_repo",
                "#{::Rails.root}/data/test/workdir")
    end

    let!(:repo) { build(:git_repository) }

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
