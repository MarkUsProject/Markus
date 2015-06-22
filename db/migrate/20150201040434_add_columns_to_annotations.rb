class AddColumnsToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :column_start, :integer
    add_column :annotations, :column_end, :integer
  end
end
