class AddTestRunIdToFeedbackFiles < ActiveRecord::Migration[6.0]
  def change
    add_reference :feedback_files, :test_runs, index: true, foreign_key: true
  end
end
