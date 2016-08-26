class RenameRunFlagsInTestScripts < ActiveRecord::Migration
  def change
    change_table :test_scripts do |t|
      t.rename :run_on_submission, :run_by_instructors
      t.rename :run_on_request, :run_by_students
    end
  end
end
