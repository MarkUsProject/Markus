class AddEditorColumnToAnnotationTexts < ActiveRecord::Migration
  def self.up
    add_column :annotation_texts, :last_editor_id, :integer
  end

  def self.down
    remove_column :annotation_texts, :last_editor
  end
end
