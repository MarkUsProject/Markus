class AddIndexToGradeEntryStudents < ActiveRecord::Migration[6.1]
  def change
    remove_index :grade_entry_students, :role_id
    add_index :grade_entry_students, [:role_id, :assessment_id], unique: true
  end
end
