class AddPeerReviewAssignmentToAssignments < ActiveRecord::Migration
  def change
    add_reference :assignments, :parent_assignment
  end
end
