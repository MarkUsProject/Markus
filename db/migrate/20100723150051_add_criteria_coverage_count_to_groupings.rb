class AddCriteriaCoverageCountToGroupings < ActiveRecord::Migration
  def self.up
    add_column :groupings, :criteria_coverage_count, :integer, :default => 0
  end

  def self.down
    remove_column :groupings, :criteria_coverage_count
  end
end
