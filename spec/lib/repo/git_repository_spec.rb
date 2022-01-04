describe GitRepository do
  context 'writes to repository permissions file' do
    before :all do
      GitRepository.public_send :update_permissions_file, { mock_repo: [:student1, :student2] }, ['instructor1']
    end

    after :all do
      FileUtils.rm Repository::PERMISSION_FILE
    end

    let(:file_contents) { File.read(Repository::PERMISSION_FILE).lines.map(&:chomp) }

    it 'give instructors access to all repos' do
      expect(file_contents[0].split(',')[0]).to eq('*')
      expect(file_contents[0].split(',')[1]).to eq('instructor1')
    end

    it 'gives other users access to specific repos' do
      expect(file_contents[1].split(',')[0]).to eq('mock_repo')
      expect(file_contents[1].split(',')[1]).to eq('student1')
      expect(file_contents[1].split(',')[2]).to eq('student2')
    end
  end
end
