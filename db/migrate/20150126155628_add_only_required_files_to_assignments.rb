class AddOnlyRequiredFilesToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :only_required_files, :boolean
  end
end
