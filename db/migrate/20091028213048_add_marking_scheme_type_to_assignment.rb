class AddMarkingSchemeTypeToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :marking_scheme_type, :string
  end

  def self.down
    remove_column :assignments, :marking_scheme_type
  end
end
