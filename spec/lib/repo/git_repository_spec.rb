describe GitRepository do
  context 'writes to repository permissions file' do

    before :all do
      GitRepository.send :__update_permissions, { mock_repo: [:student1, :student2] }, ['admin1']
    end

    after :all do
      FileUtils.rm MarkusConfigurator.markus_config_repository_permission_file
    end

    let(:file_contents) { File.read(MarkusConfigurator.markus_config_repository_permission_file).lines.map(&:chomp) }

    it 'give admins access to all repos' do
      expect(file_contents[0].split(',')[0]).to eq('*')
      expect(file_contents[0].split(',')[1]).to eq('admin1')
    end

    it 'gives other users access to specific repos' do
      expect(file_contents[1].split(',')[0]).to eq('mock_repo')
      expect(file_contents[1].split(',')[1]).to eq('student1')
      expect(file_contents[1].split(',')[2]).to eq('student2')
    end
  end
end
