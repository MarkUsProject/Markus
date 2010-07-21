class AddIsCollectedToGrouping < ActiveRecord::Migration
  def self.up
    add_column :groupings, :is_collected, :boolean, :default => false
  end

  def self.down
    remove_column :groupings, :is_collected
  end
end
