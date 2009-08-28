class ModifyPeriodsToHours < ActiveRecord::Migration
  def self.up
    remove_column :periods, :start_time
    remove_column :periods, :end_time
    add_column :periods, :hours, :float
  end

  def self.down
    remove_column :periods, :hours
    add_column :periods, :start_time, :datetime
    add_column :periods, :end_time, :datetime
  end
end
