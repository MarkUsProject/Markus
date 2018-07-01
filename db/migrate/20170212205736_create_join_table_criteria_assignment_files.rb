class CreateJoinTableCriteriaAssignmentFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :criteria_assignment_files_joins do |t|
      t.integer :criterion_id,       null: false
      t.string  :criterion_type,     null: false
      t.integer :assignment_file_id, null: false
      t.timestamps
    end
    add_foreign_key :criteria_assignment_files_joins, :assignment_files
  end
end
