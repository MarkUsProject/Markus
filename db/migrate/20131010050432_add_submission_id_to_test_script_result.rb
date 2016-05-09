class AddSubmissionIdToTestScriptResult < ActiveRecord::Migration
  def change
    add_column :test_script_results, :submission_id, :integer
  end
end
