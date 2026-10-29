class AddDisplayAverageToStudentsToAssignmentProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :assignment_properties, :display_average_to_students, :boolean, default: false, null: false
  end
end
