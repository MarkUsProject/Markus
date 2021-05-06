class AddTestGroupResultIdToFeedbackFiles < ActiveRecord::Migration[6.0]
  def change
    add_reference :feedback_files, :test_group_result, index: true, foreign_key: true
  end
end
