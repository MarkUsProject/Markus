class AddTimeToTestScriptResults < ActiveRecord::Migration[4.2]
  def change
    add_column :test_script_results, :time, :bigint, null: false
  end
end
