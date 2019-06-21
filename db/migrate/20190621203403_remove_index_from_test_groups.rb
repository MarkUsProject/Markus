class RemoveIndexFromTestGroups < ActiveRecord::Migration[5.2]
  def change
    remove_index :test_groups, name: :index_test_groups_on_assignment_id_and_name
  end
end
