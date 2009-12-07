class CreateGradeEntryStudents < ActiveRecord::Migration
  def self.up
    create_table :grade_entry_students do |t|
      t.integer :user_id
      t.integer :grade_entry_form_id
      t.boolean :released_to_student

      t.timestamps
    end
 
    add_index :grade_entry_students, [:user_id, :grade_entry_form_id], :unique => true
    
  end

  def self.down  
    remove_index :grade_entry_students, [:user_id, :grade_entry_form_id]
    drop_table :grade_entry_students
  end
end
