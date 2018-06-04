class TrackAutotestRuns3 < ActiveRecord::Migration
  def change
    remove_reference :test_script_results, :grouping
    remove_reference :test_script_results, :submission
    remove_reference :test_script_results, :requested_by, index: true, foreign_key: true
    remove_column :test_script_results, :repo_revision, :text
    rename_column :test_script_results, :stderr, :extra_info
  end
end
