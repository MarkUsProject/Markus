class CreateKeyPairs < ActiveRecord::Migration
  def change
    create_table :key_pairs do |t|
      t.integer :user_id
      t.string :user_name
      t.string :file_name

      t.timestamps
    end
  end
end
