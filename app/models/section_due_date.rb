class SectionDueDate < ApplicationRecord
  belongs_to :section
  belongs_to :assignment, inverse_of: :section_due_dates, foreign_key: :assessment_id

  # Returns the dute date for a section of an assignment. Defaults to the global
  # due date of the assignment.
  def self.due_date_for(section, assignment)
    return assignment.due_date unless assignment.section_due_dates_type

    section_due_date =
      where(section_id: section.id, assessment_id: assignment.id).first
    section_due_date.try(:due_date) || assignment.due_date
  end

end


