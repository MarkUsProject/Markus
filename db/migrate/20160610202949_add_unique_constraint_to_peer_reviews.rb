class AddUniqueConstraintToPeerReviews < ActiveRecord::Migration[4.2]
  def change
    add_index :peer_reviews, [:result_id, :reviewer_id], unique: true
  end
end
