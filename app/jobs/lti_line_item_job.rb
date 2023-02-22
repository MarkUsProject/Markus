class LtiLineItemJob < ApplicationJob
  include LtiHelper

  def self.show_status(_status)
    I18n.t('lti.create_line_item_in_progress')
  end

  def self.completed_message(_status)
    I18n.t('lti.line_item_created')
  end

  def perform(lti_deployment_ids, assessment)
    lti_deployments = LtiDeployment.where(id: lti_deployment_ids)
    lti_deployments.each do |deployment|
      create_or_update_lti_assessment(deployment, assessment)
    end
  end
end
