class AddPathToSubmissionFile < ActiveRecord::Migration[4.2]
  def self.up
    add_column :submission_files, :path, :string, :default => '/', :null => false
  end

  def self.down
    remove_column :submission_files, :path
  end
end
