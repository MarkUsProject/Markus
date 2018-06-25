class ChangeTestMarksTotalNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_default :test_results, :marks_total, 0.0
    change_column_null :test_results, :marks_total, false
    change_column_default :test_script_results, :marks_total, 0.0
    change_column_null :test_script_results, :marks_total, false
  end
end
