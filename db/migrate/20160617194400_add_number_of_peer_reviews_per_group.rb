class AddNumberOfPeerReviewsPerGroup < ActiveRecord::Migration
  def change
    add_column :assignments, :number_of_peer_reviews_per_group, :integer, unsigned: true, null: false, default: 3
  end
end
