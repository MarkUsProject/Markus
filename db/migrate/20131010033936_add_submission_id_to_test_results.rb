class AddSubmissionIdToTestResults < ActiveRecord::Migration[4.2]
  def change
    add_column :test_results, :submission_id, :integer
  end
end
