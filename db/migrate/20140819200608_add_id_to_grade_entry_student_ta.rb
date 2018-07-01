class AddIdToGradeEntryStudentTa < ActiveRecord::Migration[4.2]
  def change
    add_column :grade_entry_students_tas, :id, :primary_key
  end
end
