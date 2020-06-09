class RefactorMarkingWeightAssociation < ActiveRecord::Migration[6.0]
  def change
    remove_column :marking_weights, :is_assignment, :boolean, null: false
    remove_column :marking_weights, :gradable_item_id, :integer
    add_reference :marking_weights, :assessment, index: true, foreign_key: true, null: false
  end
end
