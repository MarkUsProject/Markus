class FixAnnotationLabelNullCategoryOk < ActiveRecord::Migration[4.2]
  def self.up
    change_column :annotation_labels, :annotation_category_id, :integer, null: true
  end

  def self.down
    change_column :annotation_labels, :annotation_category_id, :integer, null: true
  end
end
