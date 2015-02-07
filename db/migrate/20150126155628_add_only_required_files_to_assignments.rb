class AddOnlyRequiredFilesToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :only_required_files, :boolean
  end
end
