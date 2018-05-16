class ChangeSubmissionRevisionNullable < ActiveRecord::Migration
  def change
    change_column_null :submissions, :revision_identifier, true
    change_column_null :submissions, :revision_timestamp, true
  end
end
