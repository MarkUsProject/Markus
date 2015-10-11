# we need repository permission constants
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')
class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT

  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  after_update  :maintain_repository_permissions

  # for an admin, we just want all the assignment groupings submitted
  def get_num_assigned(assignment)
    assignment.groupings.size
  end

  # for an admin, we want all the assignment groupings marked completed ##################################
  def get_num_marked(assignment)
    n = 0
    assignment.groupings.each do |x|
      if x.marking_completed?
        n += 1
      end
    end
    n
  end

end
