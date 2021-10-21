class AddCourseIdToGroups < ActiveRecord::Migration[6.1]
  def change
    add_reference :groups, :course, null: false, foreign_key: true
    remove_index :groups, :group_name
    add_index :groups, [:group_name, :course_id], unique: true
  end
end
