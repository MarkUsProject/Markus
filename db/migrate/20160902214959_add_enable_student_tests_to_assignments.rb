class AddEnableStudentTestsToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :enable_student_tests, :boolean, null: false, default: false
  end
end
