require 'migration_helpers'
class CreateAnnotationLabels < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :annotation_labels do |t|
      t.column    :name,   :text
      t.column    :content, :text
      t.column :annotation_category_id, :integer,  :null => false
      t.timestamps
    end
    foreign_key(:annotation_labels, :annotation_category_id, :annotation_categories)
  end

  def self.down
    drop_table :annotation_labels
  end
end
