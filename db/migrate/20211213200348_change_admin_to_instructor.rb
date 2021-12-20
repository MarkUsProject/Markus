class ChangeAdminToInstructor < ActiveRecord::Migration[6.1]
  def change
    rename_column :groupings, :admin_approved, :instructor_approved
  end
end
