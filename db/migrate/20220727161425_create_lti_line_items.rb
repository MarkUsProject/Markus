class CreateLtiLineItems < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_line_items do |t|
      t.string :lti_line_item_id, null: false
      t.references :assessment, null: false, foreign_key: true
      t.references :lti_deployment, null: false, foreign_key: true

      t.timestamps
    end
    add_column :lti_deployments, :lms_course_id, :integer, null: true
    add_column :lti_deployments, :lms_course_name, :string, null: false
    add_index :lti_line_items, [:lti_deployment_id, :assessment_id], unique: true
  end
end
