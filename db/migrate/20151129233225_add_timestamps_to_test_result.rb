class AddTimestampsToTestResult < ActiveRecord::Migration
  def change
    change_table :test_results do |t|
      t.timestamps
    end
  end
end
