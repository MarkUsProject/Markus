class AddCreatorIdToAnnotations < ActiveRecord::Migration
  def change
    add_foreign_key :annotations, :users, column: :creator_id, null: false
    add_column :annotations, :creator_type, :string, null: false
  end
end
