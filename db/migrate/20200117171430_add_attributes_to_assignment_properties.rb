class AddAttributesToAssignmentProperties < ActiveRecord::Migration[6.0]
  def change
    add_column :assignment_properties, :anonymize_groups, :boolean, default: false, null: false
    add_column :assignment_properties, :hide_unassigned_criteria, :boolean, default: false, null: false
  end
end
