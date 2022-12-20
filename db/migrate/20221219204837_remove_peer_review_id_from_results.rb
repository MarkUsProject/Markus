class RemovePeerReviewIdFromResults < ActiveRecord::Migration[7.0]
  def up
    remove_column :results, :peer_review_id
  end
  def down
    add_reference :results, :peer_review, index: true
    add_foreign_key :results, :peer_reviews, on_delete: :cascade
    puts '-- Assigning peer review ids to results'
    Result.includes(:peer_reviews).find_each do |result|
      peer_review_id = result.peer_reviews.first&.id
      result.update!(peer_review_id: peer_review_id) unless peer_review_id.nil?
    end
  end
end
