# Model representing a user's role in a given course.
class Role < ApplicationRecord
  belongs_to :human, foreign_key: 'user_id', inverse_of: :roles
  belongs_to :course, inverse_of: :roles
  accepts_nested_attributes_for :human
  delegate_missing_to :human

  # Group relationships
  has_many :memberships, dependent: :delete_all
  has_many :groupings, through: :memberships
  has_many :notes, as: :noteable, dependent: :destroy
  has_many :annotations, as: :creator
  has_many :test_runs, dependent: :destroy
  has_many :split_pdf_logs
  has_many :assessments, through: :course
  has_many :tags

  validates_format_of :type, with: /\AStudent|Admin|Ta\z/
  validates_uniqueness_of :user_id, scope: :course_id

  # role constants
  STUDENT = 'Student'.freeze
  ADMIN = 'Admin'.freeze
  TA = 'Ta'.freeze

  # Helper methods -----------------------------------------------------

  def admin?
    instance_of?(Admin)
  end

  def ta?
    instance_of?(Ta)
  end

  def student?
    instance_of?(Student)
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
end
