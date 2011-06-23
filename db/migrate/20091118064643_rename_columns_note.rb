class RenameColumnsNote < ActiveRecord::Migration
  def self.up
    rename_column :notes, :type, :type_association
    rename_column :notes, :message, :notes_message
  end

  def self.down
    rename_column :notes, :type_association, :type
    rename_column :notes, :notes_message, :message
  end
end
