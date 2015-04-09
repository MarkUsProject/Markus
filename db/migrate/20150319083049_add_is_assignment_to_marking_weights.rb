class AddIsAssignmentToMarkingWeights < ActiveRecord::Migration
  def change
    add_column :marking_weights, :is_assignment, :boolean
  end
end
