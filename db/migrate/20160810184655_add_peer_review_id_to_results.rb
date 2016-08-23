class AddPeerReviewIdToResults < ActiveRecord::Migration
  def change
    add_reference :results, :peer_review, index: true, foreign_key: true, null: true
  end
end
