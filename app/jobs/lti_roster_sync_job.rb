class LtiRosterSyncJob < ApplicationJob
  include LtiHelper

  def self.show_status(_status)
    I18n.t('lti.start_roster_sync')
  end

  def self.completed_message(_status)
    I18n.t('lti.roster_sync_complete')
  end

  def perform(lti_deployment, course, role_types, can_create_users: false, can_create_roles: false)
    roster_error = roster_sync(lti_deployment, course, role_types, can_create_users: can_create_users,
                                                                   can_create_roles: can_create_roles)
    if roster_error
      status.update(warning_message: [status[:warning_message], I18n.t('lti.roster_sync_errors')].compact.join("\n"))
    end
  end
end
