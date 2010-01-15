class CreateTestResults < ActiveRecord::Migration
  def self.up
    create_table :test_results do |t|
      t.string :filename
      t.text :file_content
      t.integer :submission_id
      t.timestamps
    end

    add_index :test_results, [:filename]
    add_index :test_results, [:submission_id]
  end

  def self.down
    remove_index :test_results, [:filename]
    remove_index :test_results, [:submission_id]

    drop_table :test_results
  end
end
