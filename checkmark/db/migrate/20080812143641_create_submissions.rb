require 'migration_helpers'

class CreateSubmissions < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :submissions do |t|
      t.column  :user_id,              :int
      t.column  :group_number,         :int, :null => false
      t.column  :assignment_file_id,   :int
      
      t.column  :submitted_at,         :timestamp
    end
    
    add_index :submissions, [:group_id, :assignment_file_id]
    add_index :submissions, [:user_id, :group_number],  :unique => true
    
    foreign_key :submissions, :user_id,  :users
    foreign_key_no_delete :submissions, :assignment_file_id, :assignment_files
  end

  def self.down
    drop_table :submissions
  end
end
