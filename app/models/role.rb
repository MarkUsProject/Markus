# Model representing a user's role in a given course.
class Role < ApplicationRecord
  belongs_to :user
  belongs_to :course
  accepts_nested_attributes_for :user
  delegate_missing_to :user

  # Group relationships
  has_many :memberships, dependent: :delete_all
  has_many :groupings, through: :memberships
  has_many :notes, as: :noteable, dependent: :destroy
  has_many :accepted_memberships,
           -> { where membership_status: [StudentMembership::STATUSES[:accepted],
                                          StudentMembership::STATUSES[:inviter]] },
           class_name: 'Membership'
  has_many :annotations, as: :creator
  has_many :test_runs, dependent: :destroy
  has_many :split_pdf_logs

  validates_format_of :type, with: /\AStudent|Admin|Ta\z/

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

  # Determine what assessments are visible to the role.
  # By default, returns all assessments visible to the role for the current course.
  # Optional parameter assessment_type takes values "Assignment" or "GradeEntryForm". If passed one of these options,
  # only returns assessments of that type. Otherwise returns all assessment types.
  # Optional parameter assessment_id: if passed an assessment id, returns a collection containing
  # only the assessment with the given id, if it is visible to the current user.
  # If it is not visible, returns an empty collection.
  def visible_assessments(assessment_type: nil, assessment_id: nil)
    assessments = Assessment.where(is_hidden: false, course: self.course, type: assessment_type || Assessment.type)
    if self.section_id
      assessments = Assessment.left_outer_joins(:assessment_section_properties)
                              .where('assessment_section_properties.section_id': [self.section_id, nil])
      assessments = assessments.where('assessment_section_properties.is_hidden': false)
                               .or(assessments.where('assessment_section_properties.is_hidden': nil,
                                                     'assessments.is_hidden': false))
    end
    return assessments.where(id: assessment_id) if assessment_id
    assessments
  end
end
