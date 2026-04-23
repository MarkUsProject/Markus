class AddLmsTermNameToLtiDeployments < ActiveRecord::Migration[8.1]
  def change
    add_column :lti_deployments, :lms_term_name, :string
  end
end
