class AddColumnToGradersPermissions < ActiveRecord::Migration[6.0]
  def change
    add_column :grader_permissions, :download_grades_report, :boolean
  end
end
