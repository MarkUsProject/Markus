
# Maintains group information for a given user on a specific assignment
class Group < ActiveRecord::Base
  
  has_many  :memberships, :dependent => :destroy
  has_many  :members, :through => :memberships, :source => :user, 
    :conditions => "status != 'rejected'"
  has_many  :joined_members,  # members who are members of this group
  :through => :memberships, 
    :source => :user, 
    :conditions => "status = 'inviter' and status = 'accepted'"
  
  has_and_belongs_to_many :assignments
  has_many  :submissions, :class_name => 'GroupSubmission', :dependent => :destroy
  
  # Validation happens only on create since this method iterates through
  # all assignments for all members. Might be costly when done also on 
  # updates. 
  # Separate checks are done when adding members; see invite() and add_member()
  def validate_on_create
    # validate each member does not belong in more than one group
    assignments.each do |a|
      memberships.each do |m|
        user = m.user
        g = user.group_for(a.id)  # user must not be in a group for this assignment
        if m.valid? && g # user already in a group
          errors.add_to_base("User '#{user.user_name}' already belongs in a group")
        end
      end
      
      if !a.group_assignment?
        # check if groups can be formed on an assignment
        errors.add_to_base("#{a.name} is not a group assignment")
      else
        # check if number of members meet the min and max criteria
        num_members = memberships.length
        min = a.group_min
        max = a.group_max
        if num_members < min
          errors.add_to_base("You need at least #{min} members in the group.")
        elsif num_members > max
          errors.add_to_base("You can only have up to #{max} members in the group.")            
        end
      end
    end
  end
  
  # Query Functions ------------------------------------------------------
  
  # Returns the member with 'inviter' status for this group
  def inviter
    members.find(:first, :conditions => ["status = 'inviter'"])
  end
  
  # Returns true if this user has a pending status for this group; 
  # false otherwise, or if user is not in this group.
  def pending?(user)
    return status(user) == 'pending'
  end
  
  # Returns the status of this user, or nil if user is not a member
  def status(user)
    member = memberships.find_by_user_id(user.id)
    member ? member.status : nil  # return nil if user is not a member
  end
  
  # Helper function to check if group is valid, including check to see if 
  # errors added on base is empty
  def valid_with_base?
    errors.empty? && valid?
  end
  
  # Edit functions -------------------------------------------------------

  # Invites each user in 'members' by its user name, to this group
  def invite(members, status='pending')
    # overloading invite() to accept members arg as both a string and array
    members = [members] if members.is_a?(String) # put string in an array
    members.each do |m|
      next if m.blank?  # ignore blank users
      user = User.find_by_user_name(m)
      if user && user.student?
        member = add_member(user, status)
        return member if members.size == 1  # return immediately
      else
        errors.add_to_base("Username '#{m}' is not a valid student user name.")
      end
    end
  end
  
  # Add a new member to this group.
  def add_member(user, status='pending')
    assignments.each do |a|
      if user.group_for(a.id)
        errors.add_to_base("User '#{user.user_name}' already belongs in a group")
        return
      end
    end
    member = Membership.new(:user => user, :status => status)
    memberships << member
    return member
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
    
    member.status = 'rejected'
    return member.save
  end
  
  # Removes the member by its membership id
  def remove_member(mbr_id)
    member = memberships.find(mbr_id)
    member.destroy if member
  end
  
  # Removes the member rejected by its membership id
  # Used as safeguard when student deletes the record
  def remove_rejected(mbr_id)
    member = memberships.find(mbr_id)
    member.destroy if member && member.status == 'rejected'
  end
  
  # Unrefactored code...
  
  # Retrieve group object given user and assignment IDs.
  def self.find_group(user_id, assignment_id)
    user = User.find(user_id)
    return (user ? user.group_for(assignment_id) : nil)
  end
  
  # Returns array of assignment files submitted by this user's group
  def self.find_submission_files()
    return [] unless in_group?
    submitted_files = assignment_files.for_assignment
    # TODO get only the most recent submission for each file
  end
  
  #######################################################################
  # Group functions
  
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

end
