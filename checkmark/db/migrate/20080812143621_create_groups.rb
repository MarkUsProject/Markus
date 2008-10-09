require 'migration_helpers'

class CreateGroups < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :groups do |t|
      t.column  :user_id,         :int
      t.column  :group_number,    :int
      t.column  :assignment_id,   :int
      t.column  :status,          :string

      t.timestamps
    end
    
    add_index :groups, [:user_id, :group_number],  :unique => true
    add_index :groups, [:user_id, :assignment_id], :unique => true
    add_index :groups, [:group_number, :assignment_id]
    
    foreign_key_no_delete :groups, :user_id,  :users
    foreign_key_no_delete :groups, :assignment_id,  :assignments
  end

  def self.down
    drop_table(:groups) if table_exists?(:groups)
  end
end
