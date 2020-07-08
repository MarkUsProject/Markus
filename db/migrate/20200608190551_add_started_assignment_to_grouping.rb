class AddStartedAssignmentToGrouping < ActiveRecord::Migration[6.0]
  def change
    add_column :groupings, :start_time, :datetime, null: true, default: nil
  end
end
