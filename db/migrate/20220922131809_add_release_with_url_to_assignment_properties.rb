class AddReleaseWithUrlToAssignmentProperties < ActiveRecord::Migration[7.0]
  def up
    add_column :assignment_properties, :release_with_urls, :boolean, default: false, null: false
    add_column :results, :view_token, :string
    puts '-- Creating view tokens for existing results'
    Result.where(view_token: nil).each { |result| result.regenerate_view_token }
    change_column_null :results, :view_token, false
    add_column :results, :view_token_expiry, :timestamp
    add_index :results, :view_token, unique: true
  end
  def down
    remove_column :assignment_properties, :release_with_urls
    remove_index :results, :view_token
    remove_column :results, :view_token
    remove_column :results, :view_token_expiry
  end
end
