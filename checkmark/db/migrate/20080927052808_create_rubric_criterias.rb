require 'migration_helpers'
class CreateRubricCriterias < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :rubric_criterias do |t|
      t.column :name, :string,  :null => false
      t.column :description,  :text
      t.column :assignment_id,  :int, :null => false
      t.column :weight, :decimal, :null => false

      t.timestamps
    end
    add_index :rubric_criterias, [:assignment_id, :name], :unique => true
    foreign_key(:rubric_criterias, :assignment_id, :assignments)

  end

  def self.down
    drop_table :rubric_criterias
  end
end
