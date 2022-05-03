class CreateLtis < ActiveRecord::Migration[7.0]
  def change
    create_table :ltis do |t|
      t.string :client_id
      t.json :config
      t.integer :deployment_id

      t.timestamps
    end
  end
end
