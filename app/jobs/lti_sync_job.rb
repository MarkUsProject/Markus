require 'mono_logger'
class LtiSyncJob < ApplicationJob
  include LtiHelper
  queue_as :lti_sync

  def self.show_status(_status)
    I18n.t('lti.start_grade_sync')
  end

  def self.completed_message(_status)
    I18n.t('lti.grade_sync_complete')
  end

  def perform(lti_deployments, assessment, course, role: nil)
    lti_deployments.each do |deployment|
      roster_sync(deployment, course, role)
      grade_sync(deployment, assessment)
    end
  end
end
