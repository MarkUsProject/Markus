class LtiClient < ApplicationRecord
  has_many :lti_deployments
  has_many :lti_users
  validates :client_id, uniqueness: { scope: :host }
end
