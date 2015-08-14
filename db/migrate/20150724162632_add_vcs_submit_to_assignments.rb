class AddVcsSubmitToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :vcs_submit, :boolean
  end
end
