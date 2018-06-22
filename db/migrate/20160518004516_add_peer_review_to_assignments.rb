class AddPeerReviewToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :has_peer_review, :boolean, null: false, default: false
  end
end
