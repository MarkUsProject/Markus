class CreateAnnotationCategories < ActiveRecord::Migration[4.2]
  def self.up
    create_table :annotation_categories do |t|
        t.column    :name,     :text
        t.column    :position, :int
        t.timestamps
    end
  end

  def self.down
    drop_table :annotation_categories
  end
end
