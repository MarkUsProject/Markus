class CreateTags < ActiveRecord::Migration
  def up
    create_table :tags do |t|
      t.integer :tag_id,           :null => false
      t.string :content,           :null => false
      t.belongs_to :assignment_id, :null => false
    end
  end

  def down
    drop_table :tags
  end
end
