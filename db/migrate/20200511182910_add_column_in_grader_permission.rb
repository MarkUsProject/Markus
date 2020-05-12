class AddColumnInGraderPermission < ActiveRecord::Migration[6.0]
  def change
    add_column :grader_permission, :manage_grade_entry_forms, :boolean
  end
end
