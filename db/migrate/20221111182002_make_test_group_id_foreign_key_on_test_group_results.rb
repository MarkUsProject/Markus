class MakeTestGroupIdForeignKeyOnTestGroupResults < ActiveRecord::Migration[7.0]
  def up
    puts '-- removing all test_group_results not associated to a test_group'
    TestGroupResult.where(test_group_id: nil).destroy_all
    change_column_null :test_group_results, :test_group_id, false
    add_foreign_key :test_group_results, :test_groups
    add_index :test_group_results, :test_group_id
  end

  def down
    change_column_null :test_group_results, :test_group_id, true
    remove_foreign_key :test_group_results, :test_groups
    remove_index :test_group_results, :test_group_id
  end
end
