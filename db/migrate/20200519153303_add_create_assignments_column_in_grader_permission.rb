class AddCreateAssignmentsColumnInGraderPermission < ActiveRecord::Migration[6.0]
  def change
    add_column :grader_permission, :create_assignments, :boolean
  end
end
