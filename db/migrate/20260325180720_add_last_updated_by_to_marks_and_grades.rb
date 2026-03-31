class AddLastUpdatedByToMarksAndGrades < ActiveRecord::Migration[8.1]
  def change
    add_reference :marks, :last_updated_by, foreign_key: { to_table: :roles }, null: true, default: nil
    add_reference :grades, :last_updated_by, foreign_key: { to_table: :roles }, null: true, default: nil
  end
end
