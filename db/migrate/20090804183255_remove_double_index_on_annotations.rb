class RemoveDoubleIndexOnAnnotations < ActiveRecord::Migration
  def self.up
    remove_index :annotations, :name => :index_annotations_on_description_id
  end

  def self.down
    add_index :annotations, :name => :index_annotation_on_description_id
  end
end
