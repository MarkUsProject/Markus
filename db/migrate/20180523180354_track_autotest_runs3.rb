class TrackAutotestRuns3 < ActiveRecord::Migration[4.2]
  def change
    remove_reference :test_script_results, :grouping
    remove_reference :test_script_results, :submission
    remove_reference :test_script_results, :requested_by, index: true, foreign_key: { to_table: :users }
    remove_column :test_script_results, :repo_revision, :text
    rename_column :test_script_results, :stderr, :extra_info
  end
end
