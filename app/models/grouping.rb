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
    invite = Student.find(member.user_id)
    return invite
  end
  
  # Returns true if this user has a pending status for this group; 
  # false otherwise, or if user is not in this group.
  def pending?(user)
    return membership_status(user) == StudentMembership::STATUSES[:pending]
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
    member.destroy if member
  end
  
  # Removes the member rejected by its membership id
  # Used as safeguard when student deletes the record
  def remove_rejected(mbr_id)
    member = memberships.find(mbr_id)
    member.destroy if member && member.membership_status == StudentMembership::STATUSES[:rejected]
  end  
  
  # When a Grouping is created, automatically create the folder for the
  # assignment in the repository, if it doesn't already exist.
  def create_grouping_repository_folder
    require 'lib/repo/repository_factory'
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
