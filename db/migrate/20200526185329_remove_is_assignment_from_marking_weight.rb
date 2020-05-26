class RemoveIsAssignmentFromMarkingWeight < ActiveRecord::Migration[6.0]
  def change
    remove_column :marking_weights, :is_assignment, :boolean, null: false
  end
end
