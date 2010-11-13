class RemoveIndexFromResults < ActiveRecord::Migration
  def self.up
    remove_index :results, "results_u1"
  end

  def self.down
    add_index :results, :submission_id, :unique => true, :name => "results_u1"
  end
end
