class AddIsConvertedToSubmissionFile < ActiveRecord::Migration
  def self.up
    add_column :submission_files, :is_converted, :boolean, :default => false
  end

  def self.down
    remove_column :submission_files, :is_converted
  end
end
