class CreateAssignmentsTags < ActiveRecord::Migration
  def up
    create_table :assignments_tags, id: false do |t|
          t.integer :tag_id, null: false
          t.integer :assignment_id, null: false
    end

    add_index :assignments_tags, [:tag_id, :assignment_id], unique: true
  end

  def down
    remove_index :assignments_tags, column: [:tag_id, :assignment_id]
    drop_table :assignments_tags
  end
end
