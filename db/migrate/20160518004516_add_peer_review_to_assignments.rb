class AddPeerReviewToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :has_peer_review, :boolean, null: false, default: false
  end
end
