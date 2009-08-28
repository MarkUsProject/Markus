class AnnotationLabelsRemoveName < ActiveRecord::Migration
  def self.up
    remove_column :annotation_labels, :name
  end

  def self.down
    add_column :annotation_labels, :name, :text
  end
end
