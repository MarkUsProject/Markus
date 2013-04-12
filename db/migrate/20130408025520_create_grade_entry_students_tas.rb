class CreateGradeEntryStudentsTas < ActiveRecord::Migration
  def self.up
  	create_table :grade_entry_students_tas, :id => false do |t|
      t.integer  :grade_entry_student_id
      t.integer  :ta_id
  	end
  end

  def self.down
  	drop_table :grade_entry_students_tas
  end
end
