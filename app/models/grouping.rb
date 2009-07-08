require File.join(File.dirname(__FILE__),'/../../lib/repo/repository_factory')

# Represents a collection of students working together on an assignment in a group
class Grouping < ActiveRecord::Base
   
  before_create :create_grouping_repository_folder
  belongs_to :assignment
  belongs_to  :group
  has_many :memberships
  has_many :student_memberships
  has_many :ta_memberships, :class_name => "TAMembership"
  has_many :students, :through => :student_memberships, :source => :user
  has_many :accepted_students, :class_name => 'Student', :through => :student_memberships, :conditions => {'memberships.membership_status' => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]}, :source => :user
  has_many :pending_students, :class_name => 'Student', :through => :student_memberships, :conditions => {'memberships.membership_status' => StudentMembership::STATUSES[:pending]}, :source => :user
  
  has_many :submissions

  # TODO:  size_valid_groupings doesn't do what it's supposed to (IE:  return 
  # the Groupings that meet the minimum number of student_memberships for the
  # given assignment
  named_scope :size_valid_groupings, :joins => :student_memberships, :conditions => {'memberships.membership_status != ?' => StudentMembership::STATUSES[:rejected]}
  
  named_scope :approved_groupings, :conditions => {:admin_approved => true}
  named_scope :assigned_groupings, :joins => :ta_memberships

    
  # user association/validations
  validates_presence_of   :assignment_id, :message => "needs an assignment id"
  validates_associated    :assignment,    :message => "associated assignment need to be valid"
  
  validates_presence_of   :group_id, :message => "needs an group id"
  validates_associated    :group,    :message => "associated group need to be valid"
  
  def inviter?
    return membership_status == StudentMembership::STATUSES[:inviter]
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
   def invite(members, set_membership_status=StudentMembership::STATUSES[:pending])
     # overloading invite() to accept members arg as both a string and a array
     members = [members] if members.is_a?(String) # put a string in an
                                                 # array
     members.each do |m|
       next if m.blank? # ignore blank users
       user = User.find_by_user_name(m)
       if user && user.student?
         if user.hidden
           errors.add_to_base("Student account has been disabled")
         else
           member = self.add_member(user, set_membership_status)
           if member.nil?
             errors.add_to_base("Student already in a group")
           end
           return member if members.size == 1 #return immediately
         end
       else
         errors.add_to_base("Username '#{m}' is not a valid student user
         name")
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
       return member
     end
   end
  # Returns the status of this user, or nil if user is not a member
  def membership_status(user)
    member = student_memberships.find_by_user_id(user.id)
    member ? member.membership_status : nil  # return nil if user is not a member
  end
 
  # returns the numbers of memberships, all includ (inviter, pending,
  # accepted
  def student_membership_number
     return accepted_students.count 
  end
  
  # Returns true if either this Grouping has met the assignment group
  # size minimum, OR has been approved by an instructor
  def is_valid?
    return admin_approved || (pending_students.count + accepted_students.count >= assignment.group_min)
  end

  # Validates a group
  def validate_grouping
    self.admin_approved = true
    self.save
  end

  # Submission Functions
  def has_submission?
    return submissions.count > 0
  end

  def get_submission_used
    submissions.find(:first, :conditions => {:submission_version_used => true})
  end
 

# EDIT METHODS 
  # Removes the member by its membership id
  def remove_member(mbr_id)
    member = student_memberships.find(mbr_id)
    if member.membership_status == StudentMembership::STATUSES[:inviter]
       if member.grouping.student_membership_number > 1
          membership = member.grouping.accepted_students[1].memberships.find_by_grouping_id(member.grouping.id) 
          membership.membership_status = StudentMembership::STATUSES[:inviter]
          membership.save
          member.destroy if member
       else
          member.destroy if member
       end
    else
      member.destroy if member
    end
  end

  def delete_grouping
     self.student_memberships.all(:include => :user).each do |member|
       member.destroy
     end
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
  end
  
  def add_ta_by_id(ta_id)
    ta_membership = TAMembership.new
    ta_membership.user_id = ta_id
    ta_membership.grouping_id = self.id
    ta_membership.save
  end
  
  def remove_ta_by_id(ta_id)
    ta_membership = ta_memberships.find_by_user_id(ta_id)
    ta_membership.destroy
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
  
  # When a Grouping is created, automatically create the folder for the
  # assignment in the repository, if it doesn't already exist.
  def create_grouping_repository_folder
    repo = Repository.create(REPOSITORY_TYPE).open(File.join(REPOSITORY_STORAGE, group.repository_name))
    revision = repo.get_latest_revision
    assignment_folder = File.join('/', assignment.repository_folder)
    
    if revision.path_exists?(assignment_folder)
      return true
    else
      txn = repo.get_transaction("olm")
      txn.add_path(assignment_folder)
      return repo.commit(txn)  
    end
  end

end
