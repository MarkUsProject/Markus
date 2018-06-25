class RemoveUserIdFromSubmissionFiles < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :submission_files, :user_id
  end

  def self.down
    add_column :submission_files, :user_id, :int
  end
end
