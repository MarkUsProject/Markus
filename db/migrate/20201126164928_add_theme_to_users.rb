class AddThemeToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :theme, :integer, default: 1, null: false
  end
end
