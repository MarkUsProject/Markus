require 'migration_helpers'

class ModifyAnnotations < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
      delete_foreign_key :annotations, :assignment_files
      rename_column :annotations, :assignmentfile_id, :submission_file_id
      foreign_key_no_delete :annotations, :submission_file_id, :submission_files
  end

  def self.down
     delete_foreign_key :annotations, :submission_file_id, :submission_files
     rename_column :annotations, :submission_file_id, :assignmentfile_id
     foreign_key_no_delete :annotations, :assignmentfile_id, :assignment_files
     add_index :annotations, [:assignmentfile_id]
  end
end
