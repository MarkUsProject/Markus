describe MemoryRepository do
  context 'writes to repository permissions file' do
    before :all do
      @repo_loc = 'mock_repo'
      @students = [:student1, :student2]
      MemoryRepository.public_send :update_permissions_file, { @repo_loc => @students }
    end

    it 'gives users access to specific repos' do
      expect(MemoryRepository.class_variable_get(:@@permissions)[@repo_loc]).to eq(@students)
    end
  end
end
