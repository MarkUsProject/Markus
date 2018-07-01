class AddVcsSubmitToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :vcs_submit, :boolean
  end
end
