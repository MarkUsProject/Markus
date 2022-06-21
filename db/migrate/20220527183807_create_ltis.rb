class CreateLtis < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_clients do |t|
      t.string :client_id, null: false
      t.string :host, null: false
      t.belongs_to :course, null: true
      t.timestamps
    end
    create_table :lti_deployments do |t|
      t.belongs_to :lti_client, null: false
      t.belongs_to :course, null: true
      t.string :external_deployment_id, null:false
      t.timestamps
    end
    create_table :lti_users do |t|
      t.belongs_to :lti_client, null: false
      t.belongs_to :user, null: false
      t.string :lti_user_id, null: false
      t.timestamps
    end
  end
end
