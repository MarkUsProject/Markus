class RemoveAssignmentDependencyAddRepositoryFolder < ActiveRecord::Migration
  def self.up
    remove_column :assignments, :assignment_dependency_id
    add_column :assignments, :repository_folder, :string, :null => false
  end

  def self.down
    add_column :assignments, :assignment_dependency_id, :integer
    remove_column :assignments, :repository_folder
  end
end
