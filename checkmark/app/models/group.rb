
# Maintains group information for a given user on a specific assignment
class Group < ActiveRecord::Base
  
  has_many  :memberships
  has_many  :members, :through => :memberships, :source => :user
  has_many  :joined_members,  # members who are members of this group
    :through => :memberships, 
    :source => :user, 
    :conditions => "status != 'pending'"
  
  has_and_belongs_to_many :assignments
  has_many  :submissions, :class_name => 'GroupSubmission'
  
  
  def validate
    
    assignments.each do |a|
      # check if groups can be formed on an assignment
      if a.group_assignment?
        errors.add(:assignment_id, "is not a group assignment")
      end
      
      # check if number of members meet the min and max criteria
      num_members = members.length
      min = a.group_min
      max = a.group_max
      if num_members < min || num_members > max
        errors.add_to_base("Number of members must be " +
            "greater than #{min} and less than #{max}")
      end
    end
  end
  
  
  # Query Functions ------------------------------------------------------
  
  # Returns the member with 'inviter' status for this group
  def inviter
    members.find(:first, :conditions => ["status = 'inviter'"])
  end
  
  def status(user)
    member = memberships.find_by_user_id(user.id)
    member ? member.status : nil  # return nil if user is not a member
  end
  
  # Edit functions -------------------------------------------------------
  
  # Invites each user in 'members' by its user name, to this group
  def invite(members)
    members.each do |m|
      user = User.find_by_user_name(m)
      add_member(user)
    end
  end
  
  # Add a new member to this group.
  def add_member(user, status='pending')
    if user.group_for(assignment.id)
      errors.add_to_base("User #{user.user_name} is already in another group.")
    end
    memberships << Membership.new(:user => user, :status => status)
  end
  
  # Changes the membership status of member from 'pending' to 'accepted'
  def accept(user)
    member = memberships.find_by_user_id(user.id)
    raise "Invalid user" unless member # user does not belong in this group
    raise "Invalid status" unless member.status == 'pending'
    
    member.status = 'accepted'
    return member.save
  end
  
  # Removes the user from this group
  def reject(user)
    member = memberships.find_by_user_id(user.id)
    raise "Invalid user" unless member # user does not belong in this group
    raise "Invalid status" unless member.status == 'pending'  
    member.destroy
  end
  
  # Unrefactored code...
  
  # Retrieve group object given user and assignment IDs.
  def self.find_group(user_id, assignment_id)
    user = User.find(user_id)
    return (user ? user.group_for(assignment_id) : nil)
  end
  
  # Retrieves all group members for this group, including this member, 
  # for a particular assignment.
  # This also includes members that have been invited but hasn't accepted yet.
  def members2
    condition = "group_number = ? and assignment_id = #{assignment_id}"
    Group.find(:all, :conditions => [condition, group_number])
  end
  
  def joined_members2
    condition = "group_number = ? and assignment_id = #{assignment_id} and status <> 'pending'"
    Group.find(:all, :conditions => [condition, group_number])
  end
  
  def count_joined_members
    condition = "group_number = #{group_number} and " + 
      "assignment_id = #{assignment_id} and status <> 'pending'"
    Group.count_by_sql "SELECT COUNT(*) FROM groups WHERE " + condition
  end
  
  # Returns the inviter user instance for a group, given an assignment.
  # All submissions are stored using the group inviter's name
  def self.inviter(group_number, assignment_id)
    condition = "group_number = :group and assignment_id = :id and status='inviter'"
    find(:first, :conditions => [condition, 
        {:group => group_number, :id => assignment_id}])
  end
  
  # instance version of inviter
  def inviter2
    Group.inviter(group_number, assignment_id)
  end
  
  # Returns array of assignment files submitted by this user's group
  def self.find_submission_files()
    return [] unless in_group?
    submitted_files = assignment_files.for_assignment
    # TODO get only the most recent submission for each file
  end
  
  #######################################################################
  # Group functions
  
  # Form a new group with the user as inviter.  
  # Returns the group representation for this user, 
  # or nil if group cannot be formed
  def self.form_new(user_id, assignment_id)
    # TODO verify there's only one inviter per group per assignment
    new_group = create(:user_id => user_id) do |m|
      m.assignment_id = assignment_id
      m.status = 'pending'
    end
    return nil unless new_group.save # need to save before setting group number
    
    # set group id of new_group to be group number
    new_group.update_attribute(:group_number, new_group.id)
    new_group.status = 'inviter'
    unless new_group.save
      new_group.destroy
      return nil
    end
    return new_group
  end
  
  # Create a new member with a pending status for this group. Group instance 
  # must have an 'inviter' status. Return false if user has not been created.
  # TODO: we could create this in bulk for an array of user_id hashes.
  def invite(user_id)
    if can_invite?
      g = Group.create(:user_id => user_id) do |m|
        m.group_number = group_number
        m.assignment_id = assignment_id
        m.status = 'pending'
      end
      g.save
    else
      errors.add_to_base("You cannot invite another student to the group")
      return false
    end
  end
  
  
  # Rejects an invite if the group user's status is pending.  
  # Raises an error if a user tries to reject an invite if he/she
  # already joined the group.
  def reject_invite
    in_group? ? raise("Student already joined this group") : destroy
    return nil
  end
  
  # Sets the status of this group member to accepted. Does not save.
  def accept_invite
    if in_group?
      raise "Student already joined this group."
    else
      self.status = 'accepted'
    end
  end
  
  # Returns 0 if this group has no members or 1 if it has only one member
  def individual?
    return (members.empty? || members.length > 1) ? 0 : 1 
  end
  
  # Return the maximum number of grace days this group can use
  def grace_days
    condition = "group_number = ? and assignment_id = #{assignment_id}"
    members = Group.find(:all, :include => :user, :conditions => [condition, group_number])
    
    grace_day = User::GRACE_DAYS + 1
    members.each do |m|
      mgd = m.user.grace_days
      (grace_day = mgd) if mgd && mgd < grace_day
    end
    return grace_day
  end
  
  def self.get_submit_number(time=Time.now)
    t = submitted_at ? submitted_at : time
    t.strftime("%m-%d-%Y")
  end
  
  def in_group?
    status == 'inviter' || status == 'accepted'
  end
  
  def can_invite?
    status == 'inviter'
  end
  
  def use_grace_days
    return false
  end
  
  
end
