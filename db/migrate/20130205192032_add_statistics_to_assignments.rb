class AddStatisticsToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :results_median, :float
    add_column :assignments, :results_fails, :integer
    add_column :assignments, :results_zeros, :integer
  end

  def self.down
    remove_column :assignments, :results_zeros
    remove_column :assignments, :results_fails
    remove_column :assignments, :results_median
  end
end
