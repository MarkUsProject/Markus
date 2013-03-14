require 'migration_helpers'

class CreateAnnotations < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up

      create_table :annotations do |t|
        t.column :pos_start,                  :integer
        t.column :pos_end,                    :integer
        t.column :line_start,                 :integer
        t.column :line_end,                   :integer
        t.column :description_id,             :integer
        t.column :assignmentfile_id,                    :integer
      end

      add_index :annotations, [:assignmentfile_id]

      foreign_key_no_delete :annotations, :description_id, :descriptions
      foreign_key_no_delete :annotations, :assignmentfile_id, :assignment_files

  end

  def self.down
    drop_table :annotations
  end
end
