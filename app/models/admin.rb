# we need repository permission constants
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')
class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT

  after_create  :grant_repository_permissions, if: Proc.new { |admin| admin.batch_processing.blank? }
  after_destroy :revoke_repository_permissions, if: Proc.new { |admin| admin.batch_processing.blank? }
  after_update  :maintain_repository_permissions, if: Proc.new { |admin| admin.batch_processing.blank? }

end
