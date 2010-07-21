class AddGroupingQueueIdToGrouping < ActiveRecord::Migration
  def self.up
    add_column :groupings, :grouping_queue_id, :integer, :null => true
  end

  def self.down
    remove_column :groupings, :grouping_queue_id
  end
end
