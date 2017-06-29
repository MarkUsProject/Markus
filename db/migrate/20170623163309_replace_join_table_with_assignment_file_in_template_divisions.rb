class ReplaceJoinTableWithAssignmentFileInTemplateDivisions < ActiveRecord::Migration
  def change
    # Remove criteria_assignment_files_join column from TemplateDivision
    remove_reference :template_divisions, :criteria_assignment_files_join
    # Add assignment_file column from TemplateDivision
    add_reference :template_divisions, :assignment_file
  end
end
