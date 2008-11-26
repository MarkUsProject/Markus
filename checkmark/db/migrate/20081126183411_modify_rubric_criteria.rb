require 'migration_helpers'
class ModifyRubricCriteria < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    add_column :rubric_criterias, :position, :int
  end

  def self.down
    remove_column :rubric_criterias, :position
  end
end
