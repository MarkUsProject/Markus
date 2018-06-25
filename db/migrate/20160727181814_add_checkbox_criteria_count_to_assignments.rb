class AddCheckboxCriteriaCountToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :checkbox_criteria_count, :integer
  end
end
