class AddIdToGradeEntryStudentTa < ActiveRecord::Migration
  def change
    add_column :grade_entry_students_tas, :id, :primary_key
  end
end
