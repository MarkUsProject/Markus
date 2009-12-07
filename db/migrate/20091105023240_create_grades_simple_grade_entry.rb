class CreateGradesSimpleGradeEntry < ActiveRecord::Migration
  def self.up
    create_table :grades do |t|
      t.integer :grade_entry_item_id 
      t.integer :grade_entry_student_id
      t.float :grade

      t.timestamps
    end

    add_index :grades, [:grade_entry_item_id, :grade_entry_student_id], :unique => true

  end

  def self.down
    remove_index :grades, [:grade_entry_item_id, :grade_entry_student_id]
    drop_table :grades
  end

end
