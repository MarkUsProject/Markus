require 'migration_helpers'

class ModifyAnnotationsForLabels < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
      delete_foreign_key :annotations, :descriptions
      rename_column :annotations, :description_id, :annotation_label_id
      foreign_key_no_delete :annotations, :annotation_label_id, :annotation_labels
  end

  def self.down
     delete_foreign_key :annotations, :annotation_labels
     rename_column :annotations, :annotation_label_id, :description_id
     foreign_key_no_delete :annotations, :description_id, :descriptions
  end
end
