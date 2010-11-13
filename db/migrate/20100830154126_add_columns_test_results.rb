class AddColumnsTestResults < ActiveRecord::Migration
  def self.up
    # column to store status of executing ant (ie. success, failed, error)
    add_column :test_results, :status, :string
    # column to store user id of user executing the tests
    add_column :test_results, :user_id, :int
  end

  def self.down
    remove_column :test_results, :status
    remove_column :test_results, :user_id
  end
end
