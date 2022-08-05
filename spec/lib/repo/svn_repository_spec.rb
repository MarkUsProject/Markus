describe 'Subversion Repository' do
  xcontext 'writes to repository permissions file' do
    it 'is currently skipped because it requires loading SVN on travis'
    # currently skipped because it requires loading SVN on travis
    # reimpliment if we can figure out a way to call the individual function without
    # loading the whole module or if we start loading svn on travis again
    before :all do
      @repo_name = 'mock_repo'
      @students = [:student1, :student2]
      RSpec::Mocks.with_temporary_scope do
        allow(Settings.repository).to receive(:type).and_return('svn')
        Repository.get_class.public_send :update_permissions_file, { @repo_name => @students }, ['instructor1']
      end
    end

    after :all do
      FileUtils.rm Repository::PERMISSION_FILE
    end

    let(:file_contents) { File.read(Repository::PERMISSION_FILE) }

    it 'give instructors access to all repos' do
      expect(file_contents).to match(%r{\[/\]\s*\n\s*instructor1\s*=\s*rw})
    end

    it 'gives other users access to specific repos' do
      s1, s2 = @students
      expect(file_contents).to match(%r{\[#{@repo_name}:/\]\s*\n\s*#{s1}\s*=\s*rw\s*\n\s*#{s2}\s*=\s*rw})
    end
  end
end
