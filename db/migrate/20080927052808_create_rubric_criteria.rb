require 'migration_helpers'
class CreateRubricCriteria < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :rubric_criteria do |t|
      t.column :name, :string,  :null => false
      t.column :description,  :text
      t.column :assignment_id,  :int, :null => false
      t.column :weight, :decimal, :null => false

      t.timestamps
    end
    add_index :rubric_criteria, [:assignment_id, :name], :unique => true, name: :rubric_critera_index_1
    foreign_key(:rubric_criteria, :assignment_id, :assignments)

  end

  def self.down
    drop_table :rubric_criteria
  end
end
