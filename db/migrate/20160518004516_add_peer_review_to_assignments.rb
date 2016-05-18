class AddPeerReviewToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :peer_review, :boolean, default: false
  end
end
