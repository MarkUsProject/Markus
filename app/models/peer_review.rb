class PeerReview < ActiveRecord::Base
  belongs_to :result
  belongs_to :reviewer, class_name: 'Grouping'

  validates_associated :reviewer
  validates_associated :result
  validates_presence_of :reviewer
  validates_presence_of :result
  validates_numericality_of :reviewer_id, only_integer: true, greater_than: 0
  validates_numericality_of :result_id, only_integer: true, greater_than: 0

  def reviewee
    # TODO - Research optimizing or see if rails can do better
    Grouping.joins({ submissions: { results: :peer_reviews }}).where('peer_reviews.id = ?', self.id).first
  end
end
