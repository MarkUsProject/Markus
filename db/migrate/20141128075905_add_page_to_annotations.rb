class AddPageToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :page, :integer
  end
end
