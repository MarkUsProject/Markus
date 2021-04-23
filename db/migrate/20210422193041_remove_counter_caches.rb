class RemoveCounterCaches < ActiveRecord::Migration[6.0]
  def self.up
    remove_column :users, :notes_count
    remove_column :groupings, :notes_count
    remove_column :assessments, :notes_count
    remove_column :assessments, :groupings_count
    remove_column :annotation_categories, :annotation_texts_count
  end

  def self.down
    add_column :users, :notes_count, :integer, default: 0
    add_column :groupings, :notes_count, :integer, default: 0
    add_column :assessments, :notes_count, :integer, default: 0
    add_column :assessments, :groupings_count, :integer, default: 0
    add_column :annotation_categories, :annotation_texts_count, :integer, default: 0
  end
end
