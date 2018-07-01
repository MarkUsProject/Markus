class AddColumnsToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :column_start, :integer
    add_column :annotations, :column_end, :integer
  end
end
