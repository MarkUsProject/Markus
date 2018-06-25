class AddAnnotationTextsCountToAnnotationCategories < ActiveRecord::Migration[4.2]
  def change
    add_column :annotation_categories, :annotation_texts_count, :integer, :default => 0
  end
end
