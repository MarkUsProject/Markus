# Model representing a user's role in a given course.
class Role < ApplicationRecord
  belongs_to :human, foreign_key: 'user_id', inverse_of: :roles
  belongs_to :course
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

  # Determine what assessments are visible to the role.
  # By default, returns all assessments visible to the role for the current course.
  # Optional parameter assessment_type takes values "Assignment" or "GradeEntryForm". If passed one of these options,
  # only returns assessments of that type. Otherwise returns all assessment types.
  # Optional parameter assessment_id: if passed an assessment id, returns a collection containing
  # only the assessment with the given id, if it is visible to the current user.
  # If it is not visible, returns an empty collection.
  def visible_assessments(assessment_type: nil, assessment_id: nil)
    visible = self.assessments.where(is_hidden: false, type: assessment_type || Assessment.type)
    if self.section_id
      visible = self.assessments.left_outer_joins(:assessment_section_properties)
                                .where('assessment_section_properties.section_id': [self.section_id, nil])
      visible = visible.where('assessment_section_properties.is_hidden': false)
                       .or(visible.where('assessment_section_properties.is_hidden': nil,
                                         'assessments.is_hidden': false))
    end
    return visible.where(id: assessment_id) if assessment_id

    visible
  end
end
