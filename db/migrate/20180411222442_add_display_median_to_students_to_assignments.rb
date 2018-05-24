class AddDisplayMedianToStudentsToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :display_median_to_students, :boolean, default: false, null: false
  end
end
