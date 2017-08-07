class AddTimeToTestScriptResults < ActiveRecord::Migration
  def change
    add_column :test_script_results, :time, :bigint, null: false
  end
end
