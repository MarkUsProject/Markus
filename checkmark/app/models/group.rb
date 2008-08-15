
# Maintains group information for a given user on a specific assignment
class Group < ActiveRecord::Base
  
  belongs_to  :assignment
  
  # user association/validations
  belongs_to  :user
  validates_presence_of     :user_id
  validates_uniqueness_of   :user_id,       :scope => [:assignment_id], 
    :message => "is currently invited or in a group."
  validates_associated      :user
  
  # other attribute validations
  attr_protected  :status
  validates_format_of       :status,    :with => /inviter|pending|accepted/
  validates_uniqueness_of   :group_number,  :scope => [:user_id]
  
  # Validate group members are students only
  def validate_on_create
    # check if user is a student
    unless user && user.student?
      errors.add(:user_id, "must be another student")
    end
    
    # check if groups can be formed on an assignment
    if assignment.individual?
      errors.add(:assignment_id, "is not a group assignment")
    end
  end
  
  
  #######################################################################
  # Query functions
  
  # Retrieve group object given user and assignment IDs.
  def self.find_group(user_id, assignment_id)
    condition = "user_id = :user_id and assignment_id = :assignment_id"
    find(:first, :conditions => [condition, 
        {:user_id => user_id, :assignment_id => assignment_id}] )
  end
  
  # Retrieves all group members for this group, including this member, 
  # for a particular assignment.
  # This also includes members that have been invited but hasn't accepted yet.
  def members
    condition = "group_number = ? and assignment_id = #{assignment_id}"
    Group.find(:all, :conditions => [condition, group_number])
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
    new_group = Group.create(:user_id => user_id) do |m|
      m.assignment_id = assignment_id
      m.status = 'inviter'
    end
    return nil unless new_group.save # need to save before setting group number
    
    # set group id of new_group to be group number
    new_group.update_attribute(:group_number, new_group.id)
    return nil unless new_group.save
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
  
  
  def self.get_submit_number(time=Time.now)
    t = submitted_at ? submitted_at : time
    t.strftimestrftime("%m-%d-%Y")
  end
  
  def in_group?
    status == 'inviter' || status == 'accepted'
  end
  
  def can_invite?
    status == 'inviter'
  end
  
  
end
