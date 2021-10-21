class ChangeUsersToRoles < ActiveRecord::Migration[6.1]
  def change
    add_reference :grade_entry_students, :role, foreign_key:true
    remove_reference :grade_entry_students, :user, foreign_key: true

    add_reference :memberships, :role, foreign_key: true
    remove_reference :memberships, :user, foreign_key: true

    add_reference :test_runs, :role, foreign_key: true
    remove_reference :test_runs, :user, foreign_key: true
  end
end
