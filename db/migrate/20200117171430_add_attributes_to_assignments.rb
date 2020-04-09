class AddAttributesToAssignments < ActiveRecord::Migration[6.0]
  def change
    add_column :assignments, :anonymize_groups, :boolean, default: false, null: false
    add_column :assignments, :hide_unassigned_criteria, :boolean, default: false, null: false
  end
end
