class ChangeIdNumberInUsers < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :id_number, :string
  end
end
