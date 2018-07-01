class ChangeSubmissionRevisionNullable < ActiveRecord::Migration[4.2]
  def change
    change_column_null :submissions, :revision_identifier, true
    change_column_null :submissions, :revision_timestamp, true
  end
end
