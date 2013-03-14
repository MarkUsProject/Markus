class AddAssigneddGroupsCountToRubricCriteriaAndFlexibleCriteria < ActiveRecord::Migration
  def self.up
    add_column :rubric_criteria, :assigned_groups_count, :integer, :default => 0
    add_column :flexible_criteria, :assigned_groups_count, :integer, :default => 0
  end

  def self.down
    remove_column :rubric_criteria, :assigned_groups_count
    remove_column :flexible_criteria, :assigned_groups_count
  end
end
