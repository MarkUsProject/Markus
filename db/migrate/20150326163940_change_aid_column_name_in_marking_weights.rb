class ChangeAidColumnNameInMarkingWeights < ActiveRecord::Migration[4.2]
  def up
    rename_column :marking_weights, :a_id, :gradable_item_id
  end

  def down
  end
end
