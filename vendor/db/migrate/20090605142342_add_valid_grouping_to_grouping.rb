class AddValidGroupingToGrouping < ActiveRecord::Migration
  def self.up
    add_column :groupings, :valid_grouping, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :groupings, :valid_grouping
  end
end
