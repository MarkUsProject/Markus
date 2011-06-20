require 'migration_helpers'
class ModifyRubricCriteria < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    add_column :rubric_criteria, :position, :int
  end

  def self.down
    remove_column :rubric_criteria, :position
  end
end
