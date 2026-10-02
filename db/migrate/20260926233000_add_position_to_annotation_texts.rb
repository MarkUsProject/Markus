class AddPositionToAnnotationTexts < ActiveRecord::Migration[8.1]
  def change
    add_column :annotation_texts, :position, :integer, null: true, default: nil
  end
end
