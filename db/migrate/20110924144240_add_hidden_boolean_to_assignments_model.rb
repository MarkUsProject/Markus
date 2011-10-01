class AddHiddenBooleanToAssignmentsModel < ActiveRecord::Migration
  def self.up
    # Boolean flag in order to be able to hide assignments from students.
    # Default to visible assignments
    add_column :assignments, :is_hidden, :boolean, :default => false
  end

  def self.down
    remove_column :assignments, :is_hidden
  end
end
