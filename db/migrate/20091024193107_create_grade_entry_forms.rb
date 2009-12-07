class CreateGradeEntryForms < ActiveRecord::Migration
  def self.up
    create_table :grade_entry_forms do |t|
      t.string :short_identifier, :null => false
      t.string :description
      t.text :message
      t.date :date

      t.timestamps
    end

    add_index :grade_entry_forms, :short_identifier, :unique => true 
  end

  def self.down
    remove_index :grade_entry_forms, :short_identifier
    drop_table :grade_entry_forms
  end
end
