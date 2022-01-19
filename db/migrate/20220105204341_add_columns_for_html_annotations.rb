class AddColumnsForHtmlAnnotations < ActiveRecord::Migration[6.1]
  def change
    add_column :annotations, :start_node, :string
    add_column :annotations, :end_node, :string
    add_column :annotations, :start_offset, :integer
    add_column :annotations, :end_offset, :integer
  end
end
