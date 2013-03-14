require 'migration_helpers'

class RemoveAssignmentsGroups < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    drop_table :assignments_groups
  end

  def self.down
    create_table(:assignments_groups, :id => false) do |t|
      t.column  :group_id,        :int
      t.column  :assignment_id,   :int
      t.column  :status,          :string
    end

    add_index :assignments_groups, [:group_id, :assignment_id], :unique => true
    end
end
