class AddCachesToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :rubric_criterions_count, :integer
    add_column :assignments, :flexible_criterions_count, :integer
    add_column :assignments, :groupings_count, :integer
  end

  def self.down
    remove_column :assignments, :rubric_criterions_count
    remove_column :assignments, :flexible_criterions_count
    remove_column :assignments, :groupings_count
  end
end
