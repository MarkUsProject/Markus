class LtiRosterSyncJob < ApplicationJob
  include LtiHelper

  def self.show_status(_status)
    I18n.t('lti.start_roster_sync')
  end

  def self.completed_message(_status)
    I18n.t('lti.roster_sync_complete')
  end

  def perform(args)
    args = args.deep_symbolize_keys
    lti_deployment = LtiDeployment.find(args[:deployment_id])

    roster_error = roster_sync(lti_deployment, args[:role_types], can_create_users: args[:can_create_users],
                                                                  can_create_roles: args[:can_create_roles])
    if roster_error
      status.update(warning_message: [status[:warning_message], I18n.t('lti.roster_sync_errors')].compact.join("\n"))
    end
    Repository.get_class.update_permissions
  end
end
