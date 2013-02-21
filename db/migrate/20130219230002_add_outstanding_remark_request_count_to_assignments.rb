class AddOutstandingRemarkRequestCountToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :outstanding_remark_request_count, :integer
  end

  def self.down
    remove_column :assignments, :outstanding_remark_request_count
  end
end
