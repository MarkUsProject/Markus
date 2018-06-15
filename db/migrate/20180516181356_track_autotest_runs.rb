class TrackAutotestRuns < ActiveRecord::Migration[4.2]
  def change
    create_table :test_batches do |t|
      t.timestamps null: false
    end

    create_table :test_runs do |t|
      t.integer :queue_len
      t.integer :avg_pop_interval, limit: 8
      t.references :test_batch, index: true, foreign_key: true
      t.references :grouping, index: true, foreign_key: true, null: false
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end

    add_reference :test_script_results, :test_run, index: true, foreign_key: true, null: false
    add_column :test_script_results, :stderr, :text

    add_column :test_results, :time, :bigint
  end
end
