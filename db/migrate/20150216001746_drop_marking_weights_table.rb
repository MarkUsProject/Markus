class DropMarkingWeightsTable < ActiveRecord::Migration
  def up
    drop_table :marking_weights
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
