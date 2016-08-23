class ChangePeerReviewIdInResults < ActiveRecord::Migration
  def change
    # remove the old foreign key
    remove_reference :results, :peer_review, index: true, foreign_key: true

    # Add the new foreign key
    add_reference :results, :peer_review, index: true
    add_foreign_key :results, :peer_reviews, on_delete: :cascade 
  end
end
