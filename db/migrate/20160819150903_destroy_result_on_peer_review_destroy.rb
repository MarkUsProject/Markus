require 'migration_helpers'

class DestroyResultOnPeerReviewDestroy < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    # remove the old foreign key
    remove_reference :results, :peer_review, index: true, foreign_key: true

    # add new foreign key with a cascade to destroy result when peer review is destroyed
    add_column(:results, :peer_review_id, :integer)
    add_index :results, :peer_review_id
    foreign_key(:results, :peer_review_id, :peer_reviews)
  end
end
