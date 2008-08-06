require 'migration_helpers'

class CreateAssignmentFiles < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :assignment_files do |t|
      t.column  :assignment_id,   :int
      t.column  :filename,        :string,  :null => false
      
      t.timestamps
    end
    
    foreign_key(:assignment_files, :assignment_id, :assignments)
  end

  def self.down
    drop_table :assignment_files
  end
end
