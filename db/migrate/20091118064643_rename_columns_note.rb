class RenameColumnsNote < ActiveRecord::Migration
  def self.up
    rename_column :notes, :type, :type_association, :null => false
    rename_column :notes, :message, :notes_message, :null => false
  end
  
  def self.down
    rename_column :notes, :type_association, :type, :null => false
    rename_column :notes, :notes_message, :message, :null => false
  end
end
