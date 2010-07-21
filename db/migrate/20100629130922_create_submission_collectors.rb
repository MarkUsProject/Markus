class CreateSubmissionCollectors < ActiveRecord::Migration
  def self.up
    create_table :submission_collectors do |t|
      t.column :child_pid,  :integer, :null => true
      t.column :stop_child, :boolean, :default => false
      t.column :safely_stop_child_exited, :boolean, :default => false
    end
  end

  def self.down
    drop_table :submission_collectors
  end
end
