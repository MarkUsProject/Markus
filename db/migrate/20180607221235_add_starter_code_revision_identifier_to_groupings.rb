class AddStarterCodeRevisionIdentifierToGroupings < ActiveRecord::Migration[4.2]
  def change
    add_column :groupings, :starter_code_revision_identifier, :text
  end
end
