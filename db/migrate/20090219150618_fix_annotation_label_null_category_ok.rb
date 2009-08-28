class FixAnnotationLabelNullCategoryOk < ActiveRecord::Migration
  def self.up
    change_column :annotation_labels, :annotation_category_id, :integer, {:null => true}
  end

  def self.down
    change_column :annotation_labels, :annotation_category_id, :integer, {:null => false}
  end
end
