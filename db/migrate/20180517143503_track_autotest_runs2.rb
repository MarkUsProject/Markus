class TrackAutotestRuns2 < ActiveRecord::Migration[4.2]
  def change
    add_reference :test_runs, :submission, index: true, foreign_key: true
    add_column :test_runs, :revision_identifier, :text, null: false
  end
end
