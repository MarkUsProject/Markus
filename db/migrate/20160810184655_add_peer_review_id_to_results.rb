class AddPeerReviewIdToResults < ActiveRecord::Migration[4.2]
  def change
    add_reference :results, :peer_review, index: true, foreign_key: true, null: true
  end
end
