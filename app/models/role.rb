# Model representing a user's role in a given course.
class Role < ApplicationRecord
  scope :active, -> { where(hidden: false) }
  scope :inactive, -> { where(hidden: true) }
  belongs_to :user, inverse_of: :roles
  belongs_to :course, inverse_of: :roles
  accepts_nested_attributes_for :user
  delegate_missing_to :user

  # Group relationships
  has_many :memberships, dependent: :delete_all
  has_many :groupings, through: :memberships
  has_many :notes, as: :noteable, dependent: :destroy
  has_many :annotations, as: :creator
  has_many :test_runs, dependent: :destroy
  has_many :split_pdf_logs
  has_many :assessments, through: :course
  has_many :tags

  validates :type, format: { with: /\AStudent|Instructor|Ta|AdminRole\z/ }
  validates :user_id, uniqueness: { scope: :course_id }

  # Helper methods -----------------------------------------------------

  def instructor?
    is_a?(Instructor)
  end

  def ta?
    is_a?(Ta)
  end

  def student?
    is_a?(Student)
  end

  def admin_role?
    is_a?(AdminRole)
  end

  # Submission helper methods -------------------------------------------------

  def grouping_for(aid)
    groupings.find { |g| g.assessment_id == aid }
  end

  def is_a_reviewer?(assignment)
    is_a?(Student) && !assignment.nil? && assignment.is_peer_review?
  end

  def is_reviewer_for?(assignment, result)
    # aid is the peer review assignment id, and result_id
    # is the peer review result
    if assignment.nil?
      return false
    end

    group = grouping_for(Integer(assignment.id))
    if group.nil?
      return false
    end

    prs = PeerReview.where(reviewer_id: group.id)
    if prs.first.nil?
      return false
    end

    pr = prs.find { |p| p.result_id == Integer(result.id) }

    is_a?(Student) && !pr.nil?
  end

  def visible_assessments(assessment_type: nil, assessment_id: nil)
    visible = self.assessments.where(type: assessment_type || Assessment.type)
    return visible.where(id: assessment_id) if assessment_id
    visible
  end

  private

  # Helper for TA and Student subclasses that validate if the user associated with the role
  # is an end user
  def associated_user_is_an_end_user
    unless self.user.nil? || self.user.end_user?
      errors.add(:base, "non end users cannot be assigned the #{self.model_name.human} role")
    end
  end
end
