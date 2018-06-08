class AddStarterCodeRevisionIdentifierToGroupings < ActiveRecord::Migration
  def change
    add_column :groupings, :starter_code_revision_identifier, :text
  end
end
