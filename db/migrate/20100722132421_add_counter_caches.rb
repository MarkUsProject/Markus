class AddCounterCaches < ActiveRecord::Migration
  def self.up
    add_column :users, :notes_count, :integer, :default => 0
    add_column :groupings, :notes_count, :integer, :default => 0
    add_column :assignments, :notes_count, :integer, :default => 0
  end

  def self.down
    remove_column :users, :notes_count
    remove_column :groupings, :notes_count
    remove_column :assignments, :notes_count
  end
end
