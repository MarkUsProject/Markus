class CreateTags < ActiveRecord::Migration
  def up
    create_table :tags do |t|
      t.string :content,           null: false
      t.belongs_to :assignment,    null: false
    end
  end

  def down
    drop_table :tags
  end
end
