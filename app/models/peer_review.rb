class PeerReview < ActiveRecord::Base
  belongs_to :reviewer, class_name: "Grouping", foreign_key: "reviewer_id"
  belongs_to :reviewee, class_name: "Grouping", foreign_key: "reviewee_id"
  belongs_to :result

  validates_associated :reviewer
  validates_associated :reviewee
  validates_associated :result
  validates_presence_of :reviewer
  validates_presence_of :reviewee
  validates_presence_of :result
  validates_numericality_of :reviewer_id, only_integer: true,  greater_than: 0
  validates_numericality_of :reviewee_id, only_integer: true,  greater_than: 0
  validates_numericality_of :result_id, only_integer: true,  greater_than: 0
  validate :prevent_reviewer_from_being_reviewee, :do_not_allow_one_nil_review

  def do_not_allow_one_nil_review
    if reviewer.nil? ^ reviewee.nil?
      errors.add(:reviewer, 'cannot have one of either the reviewer or reviewee being nil')
    end
  end

  def prevent_reviewer_from_being_reviewee
    if not reviewer.nil? and not reviewee.nil? and reviewer == reviewee
      errors.add(:reviewer, 'cannot be the reviewer and reviewee')
    end
  end
end
