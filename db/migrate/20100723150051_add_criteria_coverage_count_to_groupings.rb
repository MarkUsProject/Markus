class AddCriteriaCoverageCountToGroupings < ActiveRecord::Migration[4.2]
  def self.up
    add_column :groupings, :criteria_coverage_count, :integer, :default => 0
  end

  def self.down
    remove_column :groupings, :criteria_coverage_count
  end
end
