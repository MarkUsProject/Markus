require 'spec_helper'

describe Repository::GitRepository do
  context 'writes to repository permissions file' do

    before :all do
      @admin = create :admin
      Repository::GitRepository.send :__update_permissions, {mock_repo: [:student1, :student2]}
    end

    after :all do
      FileUtils.rm MarkusConfigurator.markus_config_repository_permission_file
    end

    let(:file_contents) { File.read(MarkusConfigurator.markus_config_repository_permission_file).lines.map(&:chomp) }

    it 'give admins access to all repos' do
      expect(file_contents[0].split(',')[0]).to eq('*')
      expect(file_contents[0].split(',')[1]).to eq(@admin.user_name)
    end

    it 'gives other users access to specific repos' do
      expect(file_contents[1].split(',')[0]).to eq('mock_repo')
      expect(file_contents[1].split(',')[1]).to eq('student1')
      expect(file_contents[1].split(',')[2]).to eq('student2')
    end
  end
end
