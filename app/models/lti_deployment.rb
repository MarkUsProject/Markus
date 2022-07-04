class LtiDeployment < ApplicationRecord
  belongs_to :course, optional: true
  belongs_to :lti_client
  validates :external_deployment_id, uniqueness: { scope: :lti_client }
end
