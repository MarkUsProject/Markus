class LtiService < ApplicationRecord
  LTI_SERVICES = {
    namesrole: 'namesrole',
    lineitem: 'agslineitem'
  }.freeze
  belongs_to :lti_deployment
  validates :service_type, inclusion: { in: LTI_SERVICES.values }
  validates :service_type, uniqueness: { scope: :lti_deployment_id }
  has_one :course, through: :lti_deployment
end
