class CreateAutomatedTests < ActiveRecord::Migration
  def self.up
    create_table :automated_tests do |t|
      t.integer :assignment_id
      t.integer :group_id
      t.text :pretest_result
      t.text :build_result
      t.text :test_script_result

      t.timestamps
    end
  end

  def self.down
    drop_table :automated_tests
  end
end
