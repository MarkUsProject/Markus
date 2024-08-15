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
end
