class AddLocaleToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :locale, :string, null: false, default: 'en'
  end
end
