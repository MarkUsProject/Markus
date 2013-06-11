class AddIndexOnAnnotationCategories < ActiveRecord::Migration
  def self.up
    add_index :annotation_categories, [:annotation_category_name, :assignment_id], :unique => true, :name => 'index_annotation_cat_name_ass_id'
  end

  def self.down
    remove_index :annotation_categories, [:annotation_category_name, :assignment_id]
  end
end
