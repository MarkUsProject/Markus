# Represents properties of an assessment specific to a given section.
# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: assessment_section_properties
#
#  id            :integer          not null, primary key
#  due_date      :datetime
#  is_hidden     :boolean
#  start_time    :datetime
#  visible_on    :datetime
#  visible_until :datetime
#  assessment_id :bigint
#  section_id    :integer
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class AssessmentSectionProperties < ApplicationRecord
  belongs_to :section
  belongs_to :assessment, inverse_of: :assessment_section_properties

  has_one :course, through: :assessment
  validate :courses_should_match
  validates :visible_on, date: true, allow_nil: true
  validates :visible_until, date: true, allow_nil: true
  validate :visible_dates_are_valid

  # Returns the dute date for a section of an assignment. Defaults to the global
  # due date of the assignment.
  def self.due_date_for(section, assignment)
    return assignment.due_date unless assignment.section_due_dates_type

    section_due_date =
      where(section_id: section.id, assessment_id: assignment.id).first
    section_due_date.try(:due_date) || assignment.due_date
  end

  def visible_dates_are_valid
    return if visible_on.nil? || visible_until.nil?
    if visible_on >= visible_until
      errors.add(:visible_until, :before_visible_on)
    end
  end
end
