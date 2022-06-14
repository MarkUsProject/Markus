class CreateLtis < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_clients do |t|
      t.string :client_id
      t.string :host
      t.belongs_to :course, null: true
      t.timestamps
    end
    create_table :lti_deployments do |t|
      t.belongs_to :lti_client
      t.belongs_to :course, null: true
      t.string :external_deployment_id
      t.timestamps
    end
    create_table :lti_users do |t|
      t.belongs_to :lti_client
      t.belongs_to :user
      t.string :lti_user_id
      t.timestamps
    end
  end
end
