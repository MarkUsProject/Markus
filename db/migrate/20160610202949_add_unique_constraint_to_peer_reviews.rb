class AddUniqueConstraintToPeerReviews < ActiveRecord::Migration
  def change
    add_index :peer_reviews, [:result_id, :reviewer_id], unique: true
  end
end
