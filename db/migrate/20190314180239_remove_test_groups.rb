class RemoveTestGroups < ActiveRecord::Migration[5.2]
  def change
    change_table :test_group_results do |t|
      t.remove :test_group_id
      t.text :name, null: false
      t.integer :display_output, null: false, default: 0
      t.references :criterion, polymorphic: true, index: true
    end

    drop_table :test_groups
  end
end
