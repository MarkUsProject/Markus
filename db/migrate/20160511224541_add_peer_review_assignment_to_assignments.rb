class AddPeerReviewAssignmentToAssignments < ActiveRecord::Migration
  def change
    add_reference :assignments, :parent_assignment
    add_reference :assignments, :pr_assignment
  end
end
