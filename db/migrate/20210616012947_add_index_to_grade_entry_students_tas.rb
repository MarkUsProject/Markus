class AddIndexToGradeEntryStudentsTas < ActiveRecord::Migration[6.1]
  def change
    add_index :grade_entry_students_tas, [:grade_entry_student_id, :ta_id],
              unique: true,
              name: 'index_grade_entry_students_tas'
  end
end
