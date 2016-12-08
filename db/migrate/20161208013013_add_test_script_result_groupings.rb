class AddTestScriptResultGroupings < ActiveRecord::Migration
  def change
    change_table :test_script_results do |t|
      t.string :test_run
    end
  end
end