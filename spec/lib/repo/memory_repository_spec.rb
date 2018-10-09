describe MemoryRepository do
  context 'writes to repository permissions file' do

    before :all do
      @repo_loc = 'mock_repo'
      @students = [:student1, :student2]
      MemoryRepository.send :__update_permissions, { @repo_loc => @students }, ['admin1']
    end

    it 'give admins access to all repos' do
      expect(MemoryRepository.class_variable_get(:@@permissions)['*']).to eq(['admin1'])
    end

    it 'gives other users access to specific repos' do
      expect(MemoryRepository.class_variable_get(:@@permissions)[@repo_loc]).to eq(@students)
    end
  end
end
