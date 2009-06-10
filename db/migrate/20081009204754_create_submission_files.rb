require 'migration_helpers'

class CreateSubmissionFiles < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :submission_files do |t|
      t.column  :user_id,               :int
      t.column  :submission_id,         :int
      
      # submission file attributes
      t.column  :filename,              :string
      t.column  :submitted_at,          :datetime
      t.column  :status,                :string
    end
    
    foreign_key_no_delete :submission_files, :user_id, :users
    foreign_key_no_delete :submission_files, :submission_id, :submissions
    
    add_index :submission_files, :submission_id
    add_index :submission_files, :filename
  end

  def self.down
    drop_table :submission_files
  end
end
