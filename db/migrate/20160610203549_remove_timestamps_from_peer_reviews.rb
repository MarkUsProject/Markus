class RemoveTimestampsFromPeerReviews < ActiveRecord::Migration
  def change
    remove_column :peer_reviews, :created_at, :string
    remove_column :peer_reviews, :updated_at, :string
  end
end
