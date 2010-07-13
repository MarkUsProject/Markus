class AddAnnotationNumberToAnnotations < ActiveRecord::Migration
  def self.up
    add_column "annotations", "annotation_number", :integer
  end

  def self.down
    remove_column "annotations", "annotation_number"
  end
end
