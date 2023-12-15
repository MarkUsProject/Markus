class AddRequestedByToTestScriptResults < ActiveRecord::Migration[4.2]
  def change
    add_reference :test_script_results, :requested_by, index: true
    add_foreign_key :test_script_results, :users, column: :requested_by_id
    add_index :users, :api_key, :unique => true
  end
end
