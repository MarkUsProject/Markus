class ReplaceJoinTableWithAssignmentFileInTemplateDivisions < ActiveRecord::Migration[4.2]
  def change
    # Remove criteria_assignment_files_join column from TemplateDivision
    remove_reference :template_divisions, :criteria_assignment_files_join, foreign_key: true
    # Add assignment_file column from TemplateDivision
    add_reference :template_divisions, :assignment_file, foreign_key: true
  end
end
