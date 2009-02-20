class Assignment < ActiveRecord::Base
  
  has_and_belongs_to_many :groups
  has_many :rubric_criterias
  has_many :assignment_files
  has_one  :submission_rule 
  has_many :annotation_categories
  validates_associated :assignment_files
  
  validates_presence_of     :name, :group_min
  validates_uniqueness_of   :name, :case_sensitive => true
  
  validates_numericality_of :group_min, :only_integer => true,  :greater_than => 0
  validates_numericality_of :group_max, :only_integer => true

  def validate
    if (group_max && group_min) && group_max < group_min
      errors.add(:group_max, "must be greater than the minimum number of groups")
    end
  end
  
  
  # Returns a Submission instance for this user depending on whether this 
  # assignment is a group or individual assignment
  def submission_by(user)
    # submission owner is either an individual (user) or a group
    owner = group_assignment? ? group_by(user.id) : user
    return nil unless owner
    
    # create a new submission for the owner 
    # linked to this assignment, if it doesn't exist yet
    submission = owner.submissions.find_or_initialize_by_assignment_id(id)
    submission.save if submission.new_record?
    return submission
  end
  
  
  # Return true if this is a group assignment; false otherwise
  def group_assignment?
    group_min != 1 || group_max > 1
  end
  
  # Returns the group by the user for this assignment. If pending=true, 
  # it will return the group that the user has a pending invitation to.
  # Returns nil if user does not have a group for this assignment, or if it is 
  # not a group assignment
  def group_by(uid, pending=false)
    return nil unless group_assignment?
    condition = "memberships.user_id = ?"
    condition += " and memberships.status != 'rejected'"
    # add non-pending status clause to condition
    condition += " and memberships.status != 'pending'" unless pending
    groups.find(:first, :include => :memberships, :conditions => [condition, uid])
  end
  
  
  # TODO DEPRECATED: use group_assignment? instead
  # Checks if an assignment is an individually-submitted assignment (no groups)
  def individual?
    group_min == 1 && group_max == 1
  end
  
  # Returns true if a student is allowed to form groups and still allowed to 
  # invite; otherwise, returns false
  def can_invite?
    result = student_form_groups && student_invite_until.getlocal > Time.now
    return result
  end

  def total_mark
    criteria = RubricCriteria.find_all_by_assignment_id(id)
    total = 0
    criteria.each do |criterion|
      total = total + criterion.weight*4
    end
    return total
  end

end
