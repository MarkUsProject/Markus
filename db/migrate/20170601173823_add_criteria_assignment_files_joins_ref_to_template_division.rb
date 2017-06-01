class AddCriteriaAssignmentFilesJoinsRefToTemplateDivision < ActiveRecord::Migration
  def change
    add_reference :template_divisions, :criteria_assignment_files_join, index: true, foreign_key: true
  end
end
