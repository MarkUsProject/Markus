class SectionDueDate < ActiveRecord::Base
  belongs_to :section
  belongs_to :assignment

  # returns the dute date for a section and an assignment
  def self.due_date_for(section, assignment)
    d = SectionDueDate.where(assignment_id: assignment.id,
                             section_id: section.id)
                      .first
    if assignment.section_due_dates_type && !d.nil? && !d.due_date.nil?
      d.due_date
    else
      assignment.due_date
    end
  end

end


