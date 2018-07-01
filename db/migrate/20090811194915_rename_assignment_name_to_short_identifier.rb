class RenameAssignmentNameToShortIdentifier < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :assignments, :name, :short_identifier
  end

  def self.down
    rename_column :assignments, :short_identifier, :name
  end
end
