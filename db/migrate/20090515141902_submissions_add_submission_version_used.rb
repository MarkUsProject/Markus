class SubmissionsAddSubmissionVersionUsed < ActiveRecord::Migration
  def self.up
    add_column :submissions, :submission_version_used, :boolean
  end

  def self.down
    remove_column :submissions, :submission_version_used
  end
end
