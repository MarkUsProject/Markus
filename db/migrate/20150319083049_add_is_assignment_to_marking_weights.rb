class AddIsAssignmentToMarkingWeights < ActiveRecord::Migration[4.2]
  def change
    add_column :marking_weights, :is_assignment, :boolean
  end
end
