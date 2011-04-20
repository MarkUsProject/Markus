class AddIntervalToPeriods < ActiveRecord::Migration
  def self.up
    add_column :periods, :interval, :int
  end

  def self.down
    remove_column :periods, :interval
  end
end
