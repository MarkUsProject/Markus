class CreateCriterionTaAssociantion < ActiveRecord::Migration
  def self.up
    create_table :criterion_ta_associations do |t|
      t.integer :ta_id
      t.references :criterion, :polymorphic => true
      t.timestamps
    end
    add_index :criterion_ta_associations, [:ta_id]
    add_index :criterion_ta_associations, [:criterion_id]
  end

  def self.down
    remove_index :criterion_ta_associations, [:ta_id]
    remove_index :criterion_ta_associations, [:criterion_id]
    drop_table :criterion_ta_associations
  end
end
