class ChangeTestResultsTable < ActiveRecord::Migration
  def change
	rename_column :test_results, :input_description, :input
	change_column_null :test_results, :input, true
    change_column_null :test_results, :actual_output, true
    change_column_null :test_results, :expected_output, true
  end
end
