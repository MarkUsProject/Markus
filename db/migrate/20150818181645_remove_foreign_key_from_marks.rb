class RemoveForeignKeyFromMarks < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :marks, column: :markable_id
  end
end
