class SubmissionAddVersionAndCreatedTimestamp < ActiveRecord::Migration
  def self.up
    add_column :submissions, :created_at, :datetime
    add_column :submissions, :submission_version, :integer
  end

  def self.down
    remove_column :submissions, :created_at
    remove_column :submissions, :submission_version
  end
end
