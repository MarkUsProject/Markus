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

  context 'when the working copy of a repository is missing' do
    let(:repos_dir) { Dir.mktmpdir }
    let(:connect_string) { File.join(repos_dir, 'test_repo') }
    let(:tmp_repo) { GitRepository.tmp_repo(connect_string).to_s }

    before do
      GitRepository.create(connect_string, create(:course))
      FileUtils.rm_rf(tmp_repo)
    end

    after do
      FileUtils.rm_rf(repos_dir)
      FileUtils.rm_rf(tmp_repo)
    end

    it 'logs that the working copy was recloned' do
      events = capture_semantic_logger_events do
        GitRepository.access(connect_string, &:reload_non_bare_repo)
      end
      expect(events).to include(
        a_semantic_logger_event(level: :warn, name: 'GitRepository', message: 'Repository access failed',
                                payload: { repo_path: tmp_repo, reason: 'Repository is missing' }),
        a_semantic_logger_event(level: :info, name: 'GitRepository', message: 'Recloned repository',
                                payload: { repo_path: tmp_repo })
      )
    end
  end
end
