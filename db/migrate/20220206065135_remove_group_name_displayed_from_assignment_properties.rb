class RemoveGroupNameDisplayedFromAssignmentProperties < ActiveRecord::Migration[6.1]
  def change
    remove_column :assignment_properties, :group_name_displayed, :boolean, default: false, null: false
  end
end
