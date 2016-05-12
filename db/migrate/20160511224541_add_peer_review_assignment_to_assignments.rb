class AddPeerReviewAssignmentToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :parent_assignment_id, :integer, default: nil
  end
end
