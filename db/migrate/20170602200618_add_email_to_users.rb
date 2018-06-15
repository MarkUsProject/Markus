class AddEmailToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email, :string
    add_column :users, :id_number, :integer
  end
end
