class CreateGroupingQueues < ActiveRecord::Migration
  def self.up
    create_table :grouping_queues do |t|
      t.column :submission_collector_id, :integer
      t.column :priority_queue, :boolean, :default => false
    end
  end

  def self.down
    drop_table :grouping_queues
  end
end
