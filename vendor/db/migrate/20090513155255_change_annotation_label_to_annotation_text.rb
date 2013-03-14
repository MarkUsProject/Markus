require 'migration_helpers'

class ChangeAnnotationLabelToAnnotationText < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    delete_foreign_key :annotations, :annotation_labels
    #Rename the table annotation_labels to annotation_text
    rename_table :annotation_labels, :annotation_texts
    #Next, change the column name from annotations from annotation_label_id
    #to annotation_text_id
    rename_column :annotations, :annotation_label_id, :annotation_text_id
    foreign_key_no_delete :annotations, :annotation_text_id, :annotation_texts
  end

  def self.down
    delete_foreign_key :annotations, :annotation_texts
    rename_table :annotation_texts, :annotation_labels
    rename_column :annotations, :annotation_text_id, :annotation_label_id
    foreign_key_no_delete :annotations, :annotation_label_id, :annotation_labels
  end
end
