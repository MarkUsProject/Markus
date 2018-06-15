class SubmissionsAddSubmissionVersionUsed < ActiveRecord::Migration[4.2]
  def self.up
    add_column :submissions, :submission_version_used, :boolean
  end

  def self.down
    remove_column :submissions, :submission_version_used
  end
end
