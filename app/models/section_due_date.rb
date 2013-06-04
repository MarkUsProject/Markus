class SectionDueDate < ActiveRecord::Base
  belongs_to :section
  belongs_to :assignment


  # returns the dute date for a section and an assignment
  def self.due_date_for(section, assignment)
    d = SectionDueDate.find_by_assignment_id_and_section_id(assignment.id,
                                                            section.id)
    if assignment.section_due_dates_type && !d.nil? && !d.due_date.nil?
      return d.due_date
    else
      return assignment.due_date
    end
  end

end


