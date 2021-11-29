class ChangeSectionDueDatesToAssessmentSectionProperties < ActiveRecord::Migration[6.1]
  def change
    rename_table :section_due_dates, :assessment_section_properties
  end
end
