class AddTotalGradeToGradeEntryStudents < ActiveRecord::Migration
  def self.up
    add_column :grade_entry_students, :total_grade, :float
  end

  def self.down
    remove_column :grade_entry_students, :total_grade
  end
end
