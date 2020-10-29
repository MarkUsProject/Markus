class AddTimezoneToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :time_zone, :string, null: false, default: 'Eastern Time (US & Canada)'
  end
end
