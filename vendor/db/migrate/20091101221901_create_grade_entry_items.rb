class CreateGradeEntryItems < ActiveRecord::Migration
  def self.up
    create_table :grade_entry_items do |t|
      t.integer :grade_entry_form_id
      t.string :name, :null => false
      t.string :out_of, :null => false

      t.timestamps
    end

    add_index :grade_entry_items, [:grade_entry_form_id, :name], :unique => true

  end

  def self.down
    remove_index :grade_entry_items, [:grade_entry_form_id, :name]
    drop_table :grade_entry_items
  end
end
