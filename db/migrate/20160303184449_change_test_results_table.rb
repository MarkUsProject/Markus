class ChangeTestResultsTable < ActiveRecord::Migration
  def change
    rename_column :test_results, :input_description, :input
    change_column_default :test_results, :input, ''
    change_column_default :test_results, :actual_output, ''
    change_column_default :test_results, :expected_output, ''
    remove_belongs_to :test_results, :submission
    remove_belongs_to :test_results, :test_script
    remove_belongs_to :test_results, :grouping
  end
end
