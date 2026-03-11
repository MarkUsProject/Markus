# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: lti_line_items
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  assessment_id     :bigint           not null
#  lti_deployment_id :bigint           not null
#  lti_line_item_id  :string           not null
#
# Indexes
#
#  index_lti_line_items_on_assessment_id                        (assessment_id)
#  index_lti_line_items_on_lti_deployment_id                    (lti_deployment_id)
#  index_lti_line_items_on_lti_deployment_id_and_assessment_id  (lti_deployment_id,assessment_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (lti_deployment_id => lti_deployments.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class LtiLineItem < ApplicationRecord
  belongs_to :assessment
  belongs_to :lti_deployment
  validates :assessment, uniqueness: { scope: :lti_deployment_id }
end
