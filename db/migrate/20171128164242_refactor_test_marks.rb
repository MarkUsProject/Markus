class RefactorTestMarks < ActiveRecord::Migration[4.2]
  def change
    remove_column :test_scripts, :max_marks, :integer, null: false
    change_column :test_results, :marks_earned, :float, null: false, default: 0.0
    change_column :test_script_results, :marks_earned, :float, null: false, default: 0.0
    add_column :test_results, :marks_total, :float
    add_column :test_script_results, :marks_total, :float
  end
end
