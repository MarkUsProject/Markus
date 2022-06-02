class AddPositionToTestGroupsAndTestResults < ActiveRecord::Migration[7.0]
  def change
    add_column :test_groups, :position, :integer, null: false
    add_column :test_results, :position, :integer, null: false
  end
end
