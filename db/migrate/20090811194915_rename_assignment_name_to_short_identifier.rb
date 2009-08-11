class RenameAssignmentNameToShortIdentifier < ActiveRecord::Migration
  def self.up
    rename_column :assignments, :name, :short_identifier
  end

  def self.down
    rename_column :assignments, :short_identifier, :name
  end
end
