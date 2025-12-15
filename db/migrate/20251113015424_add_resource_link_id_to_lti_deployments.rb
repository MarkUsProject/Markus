class AddResourceLinkIdToLtiDeployments < ActiveRecord::Migration[8.0]
  def change
    add_column :lti_deployments, :resource_link_id, :string
  end
end
