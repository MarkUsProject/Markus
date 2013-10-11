class AddSubmissionIdToTestResults < ActiveRecord::Migration
  def change
    add_column :test_results, :submission_id, :integer
  end
end
