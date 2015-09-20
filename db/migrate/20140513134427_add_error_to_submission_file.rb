class AddErrorToSubmissionFile < ActiveRecord::Migration
  def change
    # Error column for a submission file.
    add_column :submission_files, :error_converting, :boolean, :default => false
  end
end
