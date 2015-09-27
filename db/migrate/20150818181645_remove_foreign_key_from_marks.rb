class RemoveForeignKeyFromMarks < ActiveRecord::Migration
  def change
    remove_foreign_key :marks, column: :markable_id
  end
end
