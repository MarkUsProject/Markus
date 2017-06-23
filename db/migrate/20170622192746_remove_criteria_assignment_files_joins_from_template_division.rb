class RemoveCriteriaAssignmentFilesJoinsFromTemplateDivision < ActiveRecord::Migration
  def change
    remove_reference :template_divisions, :criteria_assignment_files_join, foreign_key: true
  end
end
