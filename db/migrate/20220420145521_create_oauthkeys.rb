class CreateOauthkeys < ActiveRecord::Migration[7.0]
  def change
    create_table :oauthkeys do |t|
      t.string :private_key

      t.timestamps
    end
  end
end
