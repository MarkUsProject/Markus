class AddAnnotationTextsCountToAnnotationCategories < ActiveRecord::Migration
  def change
    add_column :annotation_categories, :annotation_texts_count, :integer, :default => 0
  end
end
