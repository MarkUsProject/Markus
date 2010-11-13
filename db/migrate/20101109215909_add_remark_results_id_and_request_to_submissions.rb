class AddRemarkResultsIdAndRequestToSubmissions < ActiveRecord::Migration
  def self.up
    add_column :submissions, :remark_result_id, :integer
    add_column :submissions, :remark_request, :text
  end

  def self.down
    remove_column :submissions, :remark_result_id
    remove_column :submissions, :remark_request
  end
end
