# we need repository permission constants
require File.join(File.dirname(__FILE__),'/../../lib/repo/repository')

# Represents a collection of students working together on an assignment in a group
class Grouping < ActiveRecord::Base
   
  before_create :create_grouping_repository_folder
  before_destroy :revoke_repository_permissions_for_students
  belongs_to :assignment
  belongs_to  :group
  has_many :memberships
  has_many :student_memberships, :order => 'id'
  has_many :accepted_student_memberships, :class_name => "StudentMembership", :conditions => {'memberships.membership_status' => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]}
  has_many :notes, :as => :noteable, :dependent => :destroy
  has_many :ta_memberships, :class_name => "TAMembership"
  has_many :students, :through => :student_memberships, :source => :user
  has_many :accepted_students, :class_name => 'Student', :through => :student_memberships, :conditions => {'memberships.membership_status' => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]}, :source => :user
  has_many :pending_students, :class_name => 'Student', :through => :student_memberships, :conditions => {'memberships.membership_status' => StudentMembership::STATUSES[:pending]}, :source => :user
  
  has_many :submissions
  has_many :grace_period_deductions, :through => :student_memberships
  
  named_scope :approved_groupings, :conditions => {:admin_approved => true}
    
  # user association/validations
  validates_presence_of   :assignment_id, :message => "needs an assignment id"
  validates_associated    :assignment,    :message => "associated assignment need to be valid"
  
  validates_presence_of   :group_id, :message => "needs an group id"
  validates_associated    :group,    :message => "associated group need to be valid"
    
  def group_name_with_student_user_names
    student_user_names = student_memberships.collect {|m| m.user.user_name }
    return group.group_name if student_user_names.size == 0
    return group.group_name + ": " + student_user_names.join(', ')
  end
  
  def display_for_note
    return assignment.short_identifier + ": " + group_name_with_student_user_names
  end

  # Query Functions ------------------------------------------------------
   
  # Returns whether or not a TA is assigned to mark this Grouping
  def has_ta_for_marking?
    return ta_memberships.count > 0
  end
  
  # Returns an array of the user_names for any TA's assigned to mark
  # this Grouping
  def get_ta_names
    return ta_memberships.collect do |membership| 
      membership.user.user_name 
    end
  end
  
  # Returns the member with 'inviter' status for this group
  def inviter
   member = student_memberships.find_by_membership_status(StudentMembership::STATUSES[:inviter])
    if member.nil?
      return nil
    end
    inviting_student = Student.find(member.user_id)
    return inviting_student
  end


  # Returns true if this user has a pending status for this group; 
  # false otherwise, or if user is not in this group.
  def pending?(user)
    return membership_status(user) == StudentMembership::STATUSES[:pending]
  end
 
  def is_inviter?(user)
    return membership_status(user) ==  StudentMembership::STATUSES[:inviter]
  end

  #invites each user in 'members' by its user name, to this group
  # TODO update unit test
  def invite(members, set_membership_status=StudentMembership::STATUSES[:pending])
    # overloading invite() to accept members arg as both a string and a array
    members = [members] if !members.instance_of?(Array) # put a string in an
                                                 # array
    members.each do |m|
      next if m.blank? # ignore blank users
      m = m.strip
      user = User.find_by_user_name(m)
      m_logger = MarkusLogger.instance
      if !user
        errors.add_to_base(I18n.t('invite_student.fail.dne', 
                                  :user_name => m))
      else
        if self.can_invite?(user)
          member = self.add_member(user, set_membership_status)
          if !member
            errors.add_to_base(I18n.t('invite_student.fail.error', 
                                      :user_name => user.user_name))
            m_logger.log(I18n.t('markus_logger.student_invited', 
                                {:inviter => "", 
                                 :invitee => user.user_name, 
                                 :error => I18n.t('invite_student.fail.error', 
                                                  :user_name => user.user_name)}), 
                                  MarkusLogger::ERROR)
          else
            m_logger.log(I18n.t('markus_logger.student_inviter_student',
                              :inviter => "", 
                              :invited => user.user_name))
          end
        end
      end
    end
  end

  # Add a new member to base
 def add_member(user, set_membership_status=StudentMembership::STATUSES[:accepted])
    if user.has_accepted_grouping_for?(self.assignment_id) || user.hidden
      return nil
    else
      member = StudentMembership.new(:user => user, :membership_status =>
      set_membership_status, :grouping => self)
      member.save
      # adjust repo permissions
      update_repository_permissions
      return member
    end
  end

  # define whether user can be invited in this grouping
  # TODO unit test
  def can_invite?(user)
    m_logger = MarkusLogger.instance
    if user && user.student?
      if user.hidden
        errors.add_to_base(I18n.t('invite_student.fail.hidden', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error => I18n.t('invite_student.fail.hidden', 
                                              :user_name =>
                                              user.user_name)}), 
                             MarkusLogger::ERROR)

        return false
      end
      if self.inviter == user
        errors.add_to_base(I18n.t('invite_student.fail.inviting_self', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error =>
                             I18n.t('invite_student.fail.inviting_self', 
                                    :user_name => user.user_name)}), 
                             MarkusLogger::ERROR)


      end
      if self.assignment.past_collection_date?
        errors.add_to_base(I18n.t('invite_student.fail.due_date_passed', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error =>
                             I18n.t('invite_student.fail.due_date_passed', 
                                    :user_name => user.user_name)}), 
                             MarkusLogger::ERROR)

        return false
      end
      if self.student_membership_number >= self.assignment.group_max
        errors.add_to_base(I18n.t('invite_student.fail.group_max_reached', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error => I18n.t('invite_student.fail.group_maw_reached', 
                                              :user_name => user.user_name)}), 
                             MarkusLogger::ERROR)
        return false
      end
      if self.assignment.section_groups_only && 
        user.section != self.inviter.section
        errors.add_to_base(I18n.t('invite_student.fail.not_same_section', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error => I18n.t('invite_student.fail.not_same_section', 
                                              :user_name => user.user_name)}), 
                             MarkusLogger::ERROR)


        return false
      end
      if user.has_accepted_grouping_for?(self.assignment.id)
        errors.add_to_base(I18n.t('invite_student.fail.already_grouped', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error => I18n.t('invite_student.fail.already_grouped', 
                                              :user_name => user.user_name)}), 
                             MarkusLogger::ERROR)
        return false
      end
      if self.pending?(user)
        errors.add_to_base(I18n.t('invite_student.fail.already_pending', 
                                  :user_name => user.user_name))
        m_logger.log(I18n.t('markus_logger.student_invited', 
                            {:inviter => "", 
                             :invitee => user.user_name, 
                             :error => I18n.t('invite_student.fail.already_pending', 
                                              :user_name => user.user_name)}), 
                            MarkusLogger::ERROR)
        return false
      end
    else
      errors.add_to_base(I18n.t('invite_student.fail.dne', 
                                :user_name => user.user_name))
      m_logger.log(I18n.t('markus_logger.student_invited', 
                          {:inviter => "", 
                           :invitee => user.user_name, 
                           :error => I18n.t('invite_student.fail.dne', 
                                            :user_name => user.user_name)}), 
                          MarkusLogger::ERROR)
      return false
    end
    return true
  end
  
  # Returns the status of this user, or nil if user is not a member
  def membership_status(user)
    member = student_memberships.find_by_user_id(user.id)
    member ? member.membership_status : nil  # return nil if user is not a member
  end
 
  # returns the numbers of memberships, all includ (inviter, pending,
  # accepted
  def student_membership_number
     return accepted_students.size + pending_students.size 
  end
  
  # Returns true if either this Grouping has met the assignment group
  # size minimum, OR has been approved by an instructor
  def is_valid?
    return admin_approved || (student_memberships.all(:conditions => ["membership_status != ?", StudentMembership::STATUSES[:rejected]]).length >= assignment.group_min)
  end

  # Validates a group
  def validate_grouping
    self.admin_approved = true
    self.save
    # update repository permissions
    update_repository_permissions
  end
  
  # Strips admin_approved privledge
  def invalidate_grouping
    self.admin_approved = false
    self.save
    # update repository permissions
    update_repository_permissions
  end

  # Grace Credit Query
  def available_grace_credits
    total = []
    accepted_students.each do |student|
      total.push(student.remaining_grace_credits)
    end
    return total.min
  end
  
  def grace_period_deduction_sum
    return grace_period_deductions.sum('deduction')
  end

  # Submission Functions
  def has_submission?
    return @has_submission if !@has_submission.nil?
    @has_submission = submissions.count > 0
  end

  def get_submission_used
    return @get_submission_used if !@get_submission_used.nil?
    @get_submission_used = submissions.find(:first, :conditions => {:submission_version_used => true})
  end
  
  def marking_completed?
    return has_submission? && get_submission_used.result.marking_state == Result::MARKING_STATES[:complete]
  end

  # EDIT METHODS 
  # Removes the member by its membership id
  def remove_member(mbr_id)
    member = student_memberships.find(mbr_id)
    if member
      # Remove repository permissions first
      #   Corner case: members are removed by admins only.
      #   Hence, we do not require to check for validity of the group
      revoke_repository_permissions_for_membership(member)
      member.destroy
      if member.membership_status == StudentMembership::STATUSES[:inviter]
         if member.grouping.accepted_student_memberships.length > 0
            membership = member.grouping.accepted_student_memberships.first
            membership.membership_status = StudentMembership::STATUSES[:inviter]
            membership.save
         end
      end
    end
  end

  def delete_grouping
    self.student_memberships.all(:include => :user).each do |member|
      member.destroy
    end
    # adjust repository permissions
    update_repository_permissions
    self.destroy
  end
  
  # Removes the member rejected by its membership id
  # Used as safeguard when student deletes the record
  def remove_rejected(mbr_id)
    member = memberships.find(mbr_id)
    member.destroy if member && member.membership_status == StudentMembership::STATUSES[:rejected]
  end 

  def decline_invitation(student)
     membership = student.memberships.find_by_grouping_id(self.id)
     membership.membership_status = StudentMembership::STATUSES[:rejected]
     membership.save
     # adjust repo permissions
     update_repository_permissions
  end
  
  def add_ta_by_id(ta_id)
    # Is there a better way to make sure that there is only one
    # TA Membership per TA per Grouping?
    if ta_memberships.find_all_by_user_id(ta_id).size < 1
      ta_membership = TAMembership.new
      ta_membership.user_id = ta_id
      ta_memberships << ta_membership
    end
  end
  
  # If a group is invalid OR valid and the user is the inviter of the group and
  # she is the _only_ member of this grouping it should be deletable
  # by this user, provided there haven't been any files submitted. Additionally,
  # the grace period for the assignment should not have passed.
  def deletable_by?(user)
    return false unless self.inviter == user
    return (!self.is_valid?) || (self.is_valid? &&
                                 self.accepted_students.size == 1 &&
                                 self.number_of_submitted_files == 0 &&
                                 self.assignment.group_assignment? &&
                                 !assignment.past_collection_date? )
  end

  # Returns the number of files submitted by this grouping for a
  # particular assignment.
  def number_of_submitted_files
    path = '/'
    repo = self.group.repo
    rev = repo.get_latest_revision
    files = rev.files_at_path(File.join(File.join(self.assignment.repository_folder, path)))
    repo.close()
    return files.keys.length
  end

  # Returns last modified date of the assignment_folder in this grouping's repository
  def assignment_folder_last_modified_date
    repo = self.group.repo
    rev = repo.get_latest_revision
    # get the full path of repository folder
    path = self.assignment.repository_folder

    # split "repo_folder_path" into two parts
    parent_path = File.dirname(path)
    folder_name = File.basename(path)

    # turn "parent_path" into absolute path
    parent_path = repo.expand_path(parent_path, "/")
    last_date = rev.directories_at_path(parent_path)[folder_name].last_modified_date
    repo.close()
    return last_date
  end

  # Returns a list of missing assignment_files yet to be submitted
  def missing_assignment_files
    missing_assignment_files = []
    self.group.access_repo do |repo|
      rev = repo.get_latest_revision
      assignment = self.assignment
      assignment.assignment_files.each do |assignment_file|
        if !rev.path_exists?(File.join(assignment.repository_folder, assignment_file.filename))
          missing_assignment_files.push(assignment_file)
        end
      end
    end
    return missing_assignment_files
  end
  
  def remove_ta_by_id(ta_id)
    ta_membership = ta_memberships.find_by_user_id(ta_id)
    if !ta_membership.nil?
      ta_membership.destroy
    end
  end
  
  def add_tas(ta_id_array)
    ta_id_array.each do |ta_id|
      add_ta_by_id(ta_id)
    end
  end
  
  def remove_tas(ta_id_array)
    ta_id_array.each do |ta_id|
      remove_ta_by_id(ta_id)
    end
  end
  
  def add_tas_by_user_name_array(ta_user_name_array)
    ta_user_name_array.each do |ta_user_name|
      ta = Ta.find_by_user_name(ta_user_name)
      add_ta_by_id(ta.id)
    end
  end

  # Returns an array containing the group names that didn't exist
  def self.assign_tas_by_csv(csv_file_contents, assignment_id)
    failures = []
    FasterCSV.parse(csv_file_contents) do |row|
      group_name = row.shift # Knocks the first item from array
      group = Group.find_by_group_name(group_name)
      if group.nil?
        failures.push(group_name)
      else
        grouping = group.grouping_for_assignment(assignment_id)
        grouping.add_tas_by_user_name_array(row) # The rest of the array
      end
    end
    return failures
  end
  
  # Update repository permissions for students, if we allow external commits
  #   see: grant_repository_permissions and revoke_repository_permissions
  def update_repository_permissions
    # we do not need to do anything if we are not accepting external
    # command-line commits
    return unless self.group.repository_external_commits_only?
    
    self.reload # VERY IMPORTANT! Make sure grouping object is not stale
    
    if self.is_valid?
      grant_repository_permissions
    else
      # grouping became invalid, remove repo permissions
      revoke_repository_permissions
    end
  end
  
  # When a Grouping is created, automatically create the folder for the
  # assignment in the repository, if it doesn't already exist.
  def create_grouping_repository_folder

    # create folder only if we are repo admin
    if self.group.repository_admin?
      self.group.access_repo do |repo|
        revision = repo.get_latest_revision
        assignment_folder = File.join('/', assignment.repository_folder)

        if revision.path_exists?(assignment_folder)
          return true
        else
          txn = self.group.repo.get_transaction("markus")
          txn.add_path(assignment_folder)
          return self.group.repo.commit(txn)
        end
      end
    end
  end
  
  private
  
  # Once a grouping is valid, grant (write) repository permissions for students
  # who have accepted memberships (including the inviter)
  #
  # precondition: grouping is valid, self.reload has been called
  def grant_repository_permissions
    memberships = self.accepted_student_memberships
    if !memberships.instance_of?(Array)
      memberships = [memberships]
    end
    memberships.each do |member|
      # Add repository read and write permissions for user,
      # if we are required to do so
      if self.group.repository_external_commits_only?
        begin
          self.group.access_repo do |repo|
            repo.add_user(member.user.user_name, Repository::Permission::READ_WRITE)
          end
        rescue Repository::UserAlreadyExistent
          # ignore case if user has permissions already
        end
      end
    end
  end
  
  # We need to revoke repository permissions for student users in certain cases.
  # 
  # For instance if the inviter has invited 2 students for a total of 3 students in
  # that group, which in turn is the required group minimum. In that case, students
  # who have accepted their membership, would have gotten repo permissions granted.
  # But once one of the 2 invited students declines to be member of that group, the group
  # becomes invalid (is below the group minimum of 3 people), and, hence, granted
  # repo permissions for student users need to be revoked again.
  # 
  # precondition: grouping is invalid, self.reload has been called
  def revoke_repository_permissions
    memberships = self.accepted_student_memberships
    if !memberships.instance_of?(Array)
      memberships = [memberships]
    end
    memberships.each do |member|
      # Revoke permissions for students
      if self.group.repository_external_commits_only?
        self.group.access_repo do |repo|
          begin
            # the following throws a Repository::UserNotFound
            if repo.get_permissions(member.user.user_name) >= Repository::Permission::ANY
              # user has some permissions, we need to remove them
              repo.remove_user(member.user.user_name)
            end
          rescue Repository::UserNotFound
            # if student has no permissions, we are safe
          end
        end
      end
    end
  end
  
  # Removes repository permissions for a single StudentMembership object
  def revoke_repository_permissions_for_membership(student_membership)
    # Revoke permissions for student
    self.group.access_repo do |repo|
      if self.group.repository_external_commits_only?
        begin
          # the following throws a Repository::UserNotFound
          if repo.get_permissions(student_membership.user.user_name) >= Repository::Permission::ANY
            # user has some permissions, we need to remove them
            repo.remove_user(student_membership.user.user_name)
          end
        rescue Repository::UserNotFound
          # if student has no permissions, we are safe
        end
      end
    end
  end
  
  # Removes any repository permissions of students for a to be destroyed
  # grouping object. see :before_destroy callback above
  def revoke_repository_permissions_for_students
    self.reload # avoid a stale object
    
    memberships = self.student_memberships # get any student memberships
    if !memberships.instance_of?(Array)
      memberships = [memberships]
    end
    memberships.each do |member|
      # Revoke permissions for students
      self.group.access_repo do |repo|
        if self.group.repository_external_commits_only?
          begin
            # the following throws a Repository::UserNotFound
            if repo.get_permissions(member.user.user_name) >= Repository::Permission::ANY
              # user has some permissions, we need to remove them
              repo.remove_user(member.user.user_name)
            end
          rescue Repository::UserNotFound
            # if student has no permissions, we are safe
          end
        end
      end
    end
  end
  
end # end class Grouping
