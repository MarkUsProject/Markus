describe 'Subversion Repository' do
  context 'writes to repository permissions file' do
    it 'is currently skipped because it requires loading SVN on travis'
    # currently skipped because it requires loading SVN on travis
    # reimpliment if we can figure out a way to call the individual function without
    # loading the whole module or if we start loading svn on travis again
    if false # reimplement by removing this conditional
      before :all do
        @repo_name = 'mock_repo'
        @students = [:student1, :student2]
        RSpec::Mocks.with_temporary_scope do
          allow(MarkusConfigurator).to receive(:markus_config_repository_type).and_return('svn')
          Repository.get_class.send :__update_permissions, {@repo_name => @students}, ['admin1']
        end
      end

      after :all do
        FileUtils.rm MarkusConfigurator.markus_config_repository_permission_file
      end

      let(:file_contents) { File.read(MarkusConfigurator.markus_config_repository_permission_file) }


      it 'give admins access to all repos' do
        expect(file_contents).to match(/\[\/\]\s*\n\s*admin1\s*=\s*rw/)
      end

      it 'gives other users access to specific repos' do
        s1, s2 = @students
        expect(file_contents).to match(/\[#{@repo_name}:\/\]\s*\n\s*#{s1}\s*=\s*rw\s*\n\s*#{s2}\s*=\s*rw/)
      end
    end
  end
end
