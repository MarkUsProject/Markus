class RemoveUnnecessarySubmissionFileFields < ActiveRecord::Migration
  def self.up
    remove_column :submission_files, :submitted_at
    remove_column :submission_files, :submission_file_status
  end

  def self.down
    add_column :submission_files, :submitted_at, :datetime
    add_column :submission_files, :submission_file_status, :string
  end
end
