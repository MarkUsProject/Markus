class ChangeCriterionsColumnsNames < ActiveRecord::Migration[4.2]
  def change
    rename_column :assignments, :rubric_criterions_count, :rubric_criteria_count
    rename_column :assignments, :flexible_criterions_count, :flexible_criteria_count
  end
end
