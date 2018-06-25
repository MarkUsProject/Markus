class AddMarkingSchemeTypeToAssignment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :marking_scheme_type, :string
  end

  def self.down
    remove_column :assignments, :marking_scheme_type
  end
end
