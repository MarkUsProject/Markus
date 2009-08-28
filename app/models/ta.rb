# we need repository permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')
class Ta < User
  
  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  
  SESSION_TIMEOUT = USER_TA_SESSION_TIMEOUT
  CSV_UPLOAD_ORDER = USER_TA_CSV_UPLOAD_ORDER  
  
  def memberships_for_assignment(assignment_id)
    assignment = Assignment.find(assignment_id)
    return assignment.ta_memberships.find_all_by_user_id(id)
  end
   
  def is_assigned_to_grouping?(grouping_id)
    grouping = Grouping.find(grouping_id)
    return grouping.ta_memberships.find_all_by_user_id(id).size > 0
  end
  
  private
  
  # Adds read and write repo permissions for each newly created TA user,
  # if need be
  def grant_repository_permissions
    Group.all.each do |group|
      if group.repository_admin?
        group.repo.add_user(self.user_name, Repository::Permission::READ_WRITE)
      end
    end
  end
  
  # Revokes read and write permissions for a deleted TA user
  def revoke_repository_permissions
    Group.all.each do |group|
      if group.repository_admin?
        group.repo.remove_user(self.user_name)
      end
    end
  end
  
end
