require 'migration_helpers'

class CreateAssignmentsGroups < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table(:assignments_groups, :id => false) do |t|
      t.column  :group_id,        :int
      t.column  :assignment_id,   :int
      t.column  :status,          :string
    end

    add_index :assignments_groups, [:group_id, :assignment_id], :unique => true
    foreign_key_no_delete :assignments_groups, :group_id,  :groups
    foreign_key_no_delete :assignments_groups, :assignment_id,  :assignments
  end

  def self.down
    drop_table :assignments_groups
  end
end
