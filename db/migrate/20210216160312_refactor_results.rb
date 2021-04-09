class RefactorResults < ActiveRecord::Migration[6.0]
  def self.up
    remove_column :assignment_properties, :results_fails, :integer
    remove_column :assignment_properties, :results_average, :integer
    remove_column :assignment_properties, :results_median, :integer
    remove_column :assignment_properties, :results_zeros, :integer
  end

  def self.down
    add_column :assignment_properties, :results_zeros,  :integer
    add_column :assignment_properties, :results_fails, :integer
    add_column :assignment_properties, :results_average, :integer
    add_column :assignment_properties, :results_median, :integer
  end
end
