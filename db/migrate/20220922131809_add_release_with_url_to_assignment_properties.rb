class AddReleaseWithUrlToAssignmentProperties < ActiveRecord::Migration[7.0]
  def change
    add_column :assignment_properties, :release_with_urls, :boolean, default: false, null: false
    add_column :results, :view_token, :string
    add_column :results, :view_token_expiry, :timestamp
    add_index :results, :view_token, unique: true
  end
end
