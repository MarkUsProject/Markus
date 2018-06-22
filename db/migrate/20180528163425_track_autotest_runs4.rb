class TrackAutotestRuns4 < ActiveRecord::Migration[4.2]
  def change
    add_column :groupings, :test_tokens, :integer, default: 0, null:false
    drop_table :tokens
  end
end
