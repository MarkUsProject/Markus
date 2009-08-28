class AddRevisionAndTimestampToSubmissions < ActiveRecord::Migration
  def self.up
    add_column :submissions, :revision_number, :integer, :null => false
    add_column :submissions, :revision_timestamp, :datetime, :null => false
  end

  def self.down
    remove_column :submissions, :revision_number
    remove_column :submissions, :revision_timestamp
  end
end
