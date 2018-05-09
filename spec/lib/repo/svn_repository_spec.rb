require 'spec_helper'

describe Repository::SubversionRepository do
  context 'writes to repository permissions file' do

    before :all do
      @admin = create :admin
      @repo_name = 'mock_repo'
      @students = [:student1, :student2]
      Repository::SubversionRepository.send :__update_permissions, {@repo_name => @students}
    end

    after :all do
      FileUtils.rm MarkusConfigurator.markus_config_repository_permission_file
    end

    let(:file_contents) { File.read(MarkusConfigurator.markus_config_repository_permission_file) }


    it 'give admins access to all repos' do
      expect(file_contents).to match(/\[\/\]\s*\n\s*#{@admin.user_name}\s*=\s*rw/)
    end

    it 'gives other users access to specific repos' do
      s1, s2 = @students
      expect(file_contents).to match(/\[#{@repo_name}:\/\]\s*\n\s*#{s1}\s*=\s*rw\s*\n\s*#{s2}\s*=\s*rw/)
    end
  end
end
