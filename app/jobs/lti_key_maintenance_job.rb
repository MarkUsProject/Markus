# Rotates the LTI signing key when due and prunes retired keys past the
# overlap window. Scheduled via Settings.resque_scheduler; only runs when
# Settings.lti.rotation.enabled is true.
class LtiKeyMaintenanceJob < ApplicationJob
  def perform
    return unless Settings.lti&.rotation&.enabled

    LtiKeyStore.rotate_if_due!
    LtiKeyStore.prune!
  end
end
