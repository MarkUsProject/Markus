class AddPeerReviewAssignmentToAssignments < ActiveRecord::Migration
  def change
    add_reference :assignments, :parent_assignment
    add_reference :assignments, :peer_review
  end
end
