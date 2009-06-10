class AnnotationCategoriesAssignedToAssignments < ActiveRecord::Migration
  def self.up
    add_column :annotation_categories, :assignment_id, :integer, {:null => false}
  end

  def self.down
    remove_column :annotation_categories, :assignment_id
  end
end
