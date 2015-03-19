require 'migration_helpers'

class CreateAssignmentFiles < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :assignment_files do |t|
      t.column  :assignment_id,   :int
      t.column  :filename,        :string,  :null => false
      t.timestamps
    end

    # only unique filenames allowed for each assignment
    add_index :assignment_files, [:assignment_id, :filename], :unique => true
    foreign_key(:assignment_files, :assignment_id, :assignments)
  end

  def self.down
    drop_table :assignment_files
  end
end
