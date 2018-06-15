class AddGroupingQueueIdToGrouping < ActiveRecord::Migration[4.2]
  def self.up
    add_column :groupings, :grouping_queue_id, :integer, :null => true
  end

  def self.down
    remove_column :groupings, :grouping_queue_id
  end
end
