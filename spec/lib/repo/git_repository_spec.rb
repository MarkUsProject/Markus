describe GitRepository do
  context 'writes to repository permissions file' do
    before do
      GitRepository.update_permissions_file({ mock_repo: [:student1, :student2] })
    end

    after do
      FileUtils.rm Repository::PERMISSION_FILE
    end

    let(:file_contents) { File.read(Repository::PERMISSION_FILE).lines.map(&:chomp) }

    it 'gives users access to specific repos' do
      expect(file_contents.first.split(',')[0]).to eq('mock_repo')
      expect(file_contents.first.split(',')[1]).to eq('student1')
      expect(file_contents.first.split(',')[2]).to eq('student2')
    end
  end

  context 'with a repository on disk' do
    include_context 'git'

    let(:course) { create(:course) }
    let(:repo_path) { File.join(Repository::ROOT_DIR, course.name, 'collision_test_repo') }

    describe '.repository_exists?' do
      it 'returns false before the repository is created' do
        expect(GitRepository.repository_exists?(repo_path)).to be false
      end

      it 'returns true once the repository is created' do
        GitRepository.create(repo_path, course)
        expect(GitRepository.repository_exists?(repo_path)).to be true
      end
    end

    describe '.create' do
      it 'raises a RepositoryCollision when the repository already exists' do
        GitRepository.create(repo_path, course)
        expect { GitRepository.create(repo_path, course) }.to raise_error(Repository::RepositoryCollision)
      end

      it 'raises an IOError when a non-repository directory holds the bare repository path' do
        FileUtils.mkdir_p(GitRepository.bare_path(repo_path))
        expect { GitRepository.create(repo_path, course) }.to raise_error(IOError)
      end
    end
  end
end
