class CreateFlexibleCriteria < ActiveRecord::Migration
  def self.up
    create_table :flexible_criteria do |t|
      t.column :flexible_criterion_name, :string, :null => false
      t.column :description, :text
      t.column :position, :int
      t.column :assignment_id, :int, :null => false
      t.column :max, :decimal, :null => false

      t.timestamps
    end
    add_index :flexible_criteria, [:assignment_id, :flexible_criterion_name], :unique => true
    add_index :flexible_criteria, :assignment_id
  end

  def self.down
    drop_table :flexible_criteria
  end
end
