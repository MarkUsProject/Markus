class LtiLineItem < ApplicationRecord
  belongs_to :assessment
  belongs_to :lti_deployment
  has_one :course, through: :assessment

  validates :assessment, uniqueness: { scope: :lti_deployment_id }
  validate :courses_should_match
end
