class LtiSyncJob < ApplicationJob
  include LtiHelper

  def self.show_status(_status)
    I18n.t('lti.start_grade_sync')
  end

  def self.completed_message(_status)
    I18n.t('lti.grade_sync_complete')
  end

  def perform(lti_deployments, assessment, course, can_create_users: false, can_create_roles: false)
    if lti_deployments.empty?
      raise I18n.t('lti.no_platform')
    end
    lti_deployments.each do |deployment|
      roster_error = roster_sync(deployment, course,
                                 [LtiDeployment::LTI_ROLES[:learner], LtiDeployment::LTI_ROLES[:ta]],
                                 can_create_users: can_create_users, can_create_roles: can_create_roles)
      if roster_error
        status.update(warning_message: [status[:warning_message], I18n.t('lti.roster_sync_errors')].compact
                                                                                                   .join("\n"))
      end
      grade_sync(deployment, assessment)
    end
  end
end
