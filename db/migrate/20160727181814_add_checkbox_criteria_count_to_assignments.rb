class AddCheckboxCriteriaCountToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :checkbox_criteria_count, :integer
  end
end
