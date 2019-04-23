class DropSubmissionCollectors < ActiveRecord::Migration[5.2]
  def change
    drop_table :submission_collectors do |t|
      t.column :child_pid,  :integer, null: true
      t.column :stop_child, :boolean, default: false
      t.column :safely_stop_child_exited, :boolean, default: false
    end

    drop_table :grouping_queues do |t|
      t.column :submission_collector_id, :integer
      t.column :priority_queue, :boolean, default: false
    end

    remove_column :groupings, :grouping_queue_id, :integer
    remove_column :groupings, :error_collecting, :boolean, default: false
  end
end
