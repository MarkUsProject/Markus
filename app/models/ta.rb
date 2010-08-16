# we need repository and permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')

class Ta < User
  
  CSV_UPLOAD_ORDER = USER_TA_CSV_UPLOAD_ORDER
  SESSION_TIMEOUT = USER_TA_SESSION_TIMEOUT
  
  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions

  has_many :criterion_ta_associations, :dependent => :delete_all
  
  def memberships_for_assignment(assignment)
    return assignment.ta_memberships.find_all_by_user_id(id, :include => {:grouping => :group})
  end
   
  def is_assigned_to_grouping?(grouping_id)
    grouping = Grouping.find(grouping_id)
    return grouping.ta_memberships.find_all_by_user_id(id).size > 0
  end
 
  # Convenience method which returns a configuration Hash for the
  # repository lib
  def self.repo_config
    # create config
    conf = Hash.new
    conf["IS_REPOSITORY_ADMIN"] = MarkusConfigurator.markus_config_repository_admin?
    conf["REPOSITORY_PERMISSION_FILE"] = MarkusConfigurator.markus_config_repository_permission_file
    return conf
  end

  def get_criterion_associations_by_assignment(assignment)
    if assignment.assign_graders_to_criteria
      return criterion_ta_associations.map do |association|
        if association.assignment == assignment
          association
        else
          nil
        end
      end.compact
    else
      return []
    end
  end

  def get_criterion_associations_count_by_assignment(assignment)
    return assignment.criterion_ta_associations.count(
      :conditions => "ta_id = #{self.id}")
  end

  def get_membership_count_by_assignment(assignment)
    return memberships.count(:include => :grouping,
      :conditions => "assignment_id = #{assignment.id}")
  end

  def get_groupings_by_assignment(assignment)
    return groupings.all(:conditions => {:assignment_id => assignment.id},
      :include => [:students, :tas, :group, :assignment])
  end
  
  private
  
  # Adds read and write repo permissions for each newly created TA user,
  # if need be
  def grant_repository_permissions
    # If we're not the repository admin, bail out
    return if !MarkusConfigurator.markus_config_repository_admin?
    
    conf = Ta.repo_config
    repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type, conf)
    repo_names = Group.all.collect do |group| File.join(MarkusConfigurator.markus_config_repository_storage, group.repository_name) end

    repo.set_bulk_permissions(repo_names, {self.user_name => Repository::Permission::READ_WRITE})
  end
  
  # Revokes read and write permissions for a deleted TA user
  def revoke_repository_permissions
    return if !MarkusConfigurator.markus_config_repository_admin?
    
    conf = Ta.repo_config
    repo = Repository.get_class(markus_config_repository_type, conf)
    repo_names = Group.all.collect do |group| File.join(MarkusConfigurator.markus_config_repository_storage, group.repository_name) end
    repo.delete_bulk_permissions(repo_names, [self.user_name])
  end
  
end
