require 'migration_helpers'
class CreateRubricLevels < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :rubric_levels do |t|
      t.column :rubric_criteria_id, :integer,  :null => false
      t.column :name,  :string, :null => false
      t.column :description,  :text
      t.column :level, :integer, :null => false
      t.timestamps
    end
    foreign_key(:rubric_levels, :rubric_criteria_id, :rubric_criterias)

  end

  def self.down
    drop_table :rubric_levels
  end
end
