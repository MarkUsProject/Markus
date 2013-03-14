class ModifyTokensPerDayInAssignment < ActiveRecord::Migration
  def self.up
    remove_column :assignments, :tokens_per_day
    add_column :assignments, :tokens_per_day, :int, :null => false, :default => 0
  end

  def self.down
    remove_column :assignments, :tokens_per_day
    add_column :assignments, :tokens_per_day, :int
  end
end
