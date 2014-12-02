class AddPageToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :page, :integer
  end
end
