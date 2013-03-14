class AddTimestampToSubmissions < ActiveRecord::Migration
  def self.up
    add_column :submissions, :remark_request_timestamp, :datetime
  end

  def self.down
    remove_column :submissions, :remark_request_timestamp
  end
end
