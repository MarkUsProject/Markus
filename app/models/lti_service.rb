class LtiService < ApplicationRecord
  belongs_to :lti_deployment
  validates :service_type, format: { with: /\Anamesroles\z/ }
  validates :service_type, uniqueness: { scope: :lti_deployment_id }
end
