class AddAssignmentDependencyToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :assignment_dependency_id, :int
  end

  def self.down
    remove_column :assignments, :assignment_dependency_id
  end
end
