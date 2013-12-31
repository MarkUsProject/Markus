class AddUserIdToAnnotationText < ActiveRecord::Migration
  def self.up
    add_column :annotation_texts, :creator_id, :integer
  end

  def self.down
    remove_column :annotation_texts, :creator_id
  end
end
