class RenameColumnsNote < ActiveRecord::Migration
  def self.up
    rename :notes, :type, :type_association, :null => false
    rename :notes, :message, :notes_message, :null => false
  end
  
  def self.down
    rename :notes, :type_association, :type, :null => false
    rename :notes, :notes_message, :message, :null => false
  end
end
