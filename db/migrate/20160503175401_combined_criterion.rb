class CombinedCriterion < ActiveRecord::Migration
  extend MigrationHelpers
  def change
    rename_column :rubric_criteria, :rubric_criterion_name, :name
    rename_column :flexible_criteria, :flexible_criterion_name, :name
  end
end
