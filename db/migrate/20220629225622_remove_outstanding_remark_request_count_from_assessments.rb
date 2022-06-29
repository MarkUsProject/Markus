class RemoveOutstandingRemarkRequestCountFromAssessments < ActiveRecord::Migration[7.0]
  def change
    remove_column :assessments, :outstanding_remark_request_count, :integer
  end
end
