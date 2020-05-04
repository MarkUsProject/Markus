class AddMailSubscribedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :mail_subscribed, :boolean, default: true
  end
end
