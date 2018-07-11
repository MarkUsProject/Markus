class ModifyRubricCriteria < ActiveRecord::Migration[4.2]
  extend MigrationHelpers

  def self.up
    add_column :rubric_criteria, :position, :int
  end

  def self.down
    remove_column :rubric_criteria, :position
  end
end
