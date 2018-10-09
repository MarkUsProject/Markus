class ChangeTestRunsRevisionNullable < ActiveRecord::Migration[5.2]
  def change
    change_column_null :test_runs, :revision_identifier, true
  end
end
