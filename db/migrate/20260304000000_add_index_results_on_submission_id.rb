class AddIndexResultsOnSubmissionId < ActiveRecord::Migration[8.0]
  def change
    add_index :results, :submission_id
  end
end
