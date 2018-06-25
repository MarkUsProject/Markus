class AddResultsAverage < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :results_average, :float
  end

  def self.down
    add_column :assignments, :results_average
  end
end
