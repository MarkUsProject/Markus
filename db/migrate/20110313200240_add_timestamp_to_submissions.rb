class AddTimestampToSubmissions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :submissions, :remark_request_timestamp, :datetime
  end

  def self.down
    remove_column :submissions, :remark_request_timestamp
  end
end
