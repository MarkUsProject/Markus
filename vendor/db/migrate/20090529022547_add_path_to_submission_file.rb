class AddPathToSubmissionFile < ActiveRecord::Migration
  def self.up
    add_column :submission_files, :path, :string, :default => '/', :null => false
  end

  def self.down
    remove_column :submission_files, :path
  end
end
