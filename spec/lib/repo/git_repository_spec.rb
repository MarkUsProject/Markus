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

    describe '.bulk_access', if: File.directory?('/proc/self/fd') do
      let(:repo_paths) do
        Array.new(8) do |i|
          path = File.join(Repository::ROOT_DIR, course.name, "bulk_access_repo_#{i}")
          GitRepository.create(path, course)
          # pack the repository's objects, as happens to repositories that students push to
          system('git', '-C', GitRepository.bare_path(path), 'gc', '--quiet', exception: true)
          path
        end
      end

      # Returns the number of file descriptors this process has open on files in the repositories
      def open_repo_file_count
        Dir.children('/proc/self/fd').count do |fd|
          File.readlink("/proc/self/fd/#{fd}").start_with?(Repository::ROOT_DIR)
        rescue SystemCallError
          false # the file descriptor was closed while listing
        end
      end

      before { stub_const('Repository::AbstractRepository::BULK_ACCESS_RELEASE_INTERVAL', 3) }

      it 'limits the number of files held open after accessing many repositories' do
        repo_paths
        open_file_counts = GitRepository.bulk_access do
          repo_paths.map do |path|
            GitRepository.access(path, &:get_all_revisions)
            open_repo_file_count
          end
        end
        expect(open_file_counts.max).to be <= Repository::AbstractRepository::BULK_ACCESS_RELEASE_INTERVAL
      end
    end
  end
end
