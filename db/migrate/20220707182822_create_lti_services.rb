class CreateLtiServices < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_services do |t|
      t.references :lti_deployment, null: false, foreign_key: true
      t.string :service_type, null: false
      t.string :url, null: false

      t.timestamps
    end
    add_index :lti_services, [:lti_deployment_id, :service_type], unique: true
    add_index :lti_users, [:user_id, :lti_client_id], unique: true
  end
end
