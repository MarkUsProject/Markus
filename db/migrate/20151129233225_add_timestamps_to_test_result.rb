class AddTimestampsToTestResult < ActiveRecord::Migration[4.2]
  def change
    change_table :test_results do |t|
      t.timestamps
    end
  end
end
