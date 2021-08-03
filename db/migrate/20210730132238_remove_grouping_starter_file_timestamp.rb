class RemoveGroupingStarterFileTimestamp < ActiveRecord::Migration[6.1]
  def change
    remove_column :groupings, :starter_file_timestamp
  end
end
