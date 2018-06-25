class AddEnableStudentTestsToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :enable_student_tests, :boolean, null: false, default: false
  end
end
