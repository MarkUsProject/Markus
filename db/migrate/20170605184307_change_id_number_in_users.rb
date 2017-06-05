class ChangeIdNumberInUsers < ActiveRecord::Migration
  def change
    change_column :users, :id_number, :string
  end
end
