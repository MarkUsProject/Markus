class CreateLtis < ActiveRecord::Migration[7.0]
  def change
    create_table :ltis do |t|
      t.string :client_id
      t.string :deployment_id
      t.string :host
      t.belongs_to :course, null: true

      t.timestamps
    end
    add_column :users, :lti_id, :string, null: true
  end
end
