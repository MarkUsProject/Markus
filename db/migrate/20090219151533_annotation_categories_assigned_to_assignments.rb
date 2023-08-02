class AnnotationCategoriesAssignedToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :annotation_categories, :assignment_id, :integer, null: false
  end

  def self.down
    remove_column :annotation_categories, :assignment_id
  end
end
