# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: lti_services
#
#  id                :bigint           not null, primary key
#  service_type      :string           not null
#  url               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  lti_deployment_id :bigint           not null
#
# Indexes
#
#  index_lti_services_on_lti_deployment_id                   (lti_deployment_id)
#  index_lti_services_on_lti_deployment_id_and_service_type  (lti_deployment_id,service_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (lti_deployment_id => lti_deployments.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class LtiService < ApplicationRecord
  LTI_SERVICES = {
    namesrole: 'namesrole',
    lineitem: 'agslineitem'
  }.freeze
  belongs_to :lti_deployment
  validates :service_type, inclusion: { in: LTI_SERVICES.values }
  validates :service_type, uniqueness: { scope: :lti_deployment_id }
end
