class AddAssignGradersToCriteriaToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :assign_graders_to_criteria, :boolean, :default => false
  end

  def self.down
    remove_column :assignments, :assign_graders_to_criteria
  end
end
