require 'spec_helper'

describe Repository::MemoryRepository do
  context 'writes to repository permissions file' do

    before :all do
      @admin = create :admin
      @repo_loc = 'mock_repo'
      @students = [:student1, :student2]
      Repository::MemoryRepository.send :__update_permissions, { @repo_loc => @students }
    end

    it 'give admins access to all repos' do
      expect(Repository::MemoryRepository.class_variable_get(:@@permissions)['*']).to eq([@admin.user_name])
    end

    it 'gives other users access to specific repos' do
      expect(Repository::MemoryRepository.class_variable_get(:@@permissions)[@repo_loc]).to eq(@students)
    end
  end
end
