class TurnNotesMessageToTextField < ActiveRecord::Migration
  def self.up
    change_column :notes, :notes_message, :text, :null => false
  end

  def self.down
    change_column :notes, :notes_message, :string, :null => false
  end
end
