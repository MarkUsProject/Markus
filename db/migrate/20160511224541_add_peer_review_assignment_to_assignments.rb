class AddPeerReviewAssignmentToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_reference :assignments, :parent_assignment
  end
end
