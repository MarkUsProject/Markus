class LtiLineItem < ApplicationRecord
  belongs_to :assessment
  belongs_to :lti_deployment
  validates :assessment, uniqueness: { scope: :lti_deployment_id }
end
