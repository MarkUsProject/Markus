class AddAssignmentFileToTemplateDivision < ActiveRecord::Migration
  def change
    add_reference :template_divisions, :assignment_file, foreign_key: true
  end
end
