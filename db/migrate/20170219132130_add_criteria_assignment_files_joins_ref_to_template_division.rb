class AddCriteriaAssignmentFilesJoinsRefToTemplateDivision < ActiveRecord::Migration[4.2]
  def change
    add_reference :template_divisions, :criteria_assignment_files_join, foreign_key: true
  end
end
