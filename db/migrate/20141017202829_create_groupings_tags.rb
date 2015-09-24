class CreateGroupingsTags < ActiveRecord::Migration
  def up
    create_table :groupings_tags, id: false do |t|
      t.integer :tag_id, null: false
      t.integer :grouping_id, null: false
    end

    add_index :groupings_tags, [:tag_id, :grouping_id], unique: true
  end

  def down
    remove_index :groupings_tags, column: [:tag_id, :grouping_id]
    drop_table :groupings_tags
  end
end
