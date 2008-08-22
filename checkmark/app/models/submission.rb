class Submission < ActiveRecord::Base
  
  belongs_to  :assignment_file
  
  
  # TODO cannot submit if pending
  # TODO if assignment is individual, user_id is used as group_number
  # TODO test distinct keywords
  
  # returns assignment files submitted by this group
  def self.submitted_files(group_number, aid)
    return nil unless group_number
    
    conditions = "s.group_number = #{group_number} and a.assignment_id = #{aid}"
    find(:all, :select => "DISTINCT assignment_file_id",
      :joins => "as s inner join assignment_files as a on s.assignment_file_id = a.id",
      :conditions => conditions)
  end
  
  # Creates a new submission record for this assignment
  def self.create_submission(user, assignment, filename, submitted_at)
    # TODO return error messages instead of nil or add errors
    group = Group.find_group(user.id, assignment.id)  # verification
    return nil unless group && group.in_group?
    return nil unless user.id == group.user_id
    
    group_num = assignment.individual? ? user.id : group.group_number
    assignment_file = assignment.find(:filename => filename)
    
    a_submission = create do |s|
      s.assignment_file_id = assignment_file.id
      s.user_id = user.id
      s.group_number = group_num
      s.submitted_at = submitted_at
    end
    
    return (a_submission.save ? submission : nil)
  end
  
  # Returns the number of grace days used by this user or group for this assignment
  # If assignment is individual, group_number must be the user id.
  def self.get_used_grace_days(user, group_number, assignment)
    cond_val = {
      :uid => user.id,
      :group => group_number, 
      :aid => assignment.id
    }
    
    # scope out assignment files to be for this user or for the group
    conditions = assignment.individual? ? "user_id = :uid and " : ""
    conditions += "group_number = :group and a.assignment_id = :aid"
    
    sub = find(:first, :order => "submitted_at DESC", 
      :joins => "inner join assignment_files as a on submissions.assignment_file_id = a.id",
      :conditions => [conditions, cond_val])
    return 0 unless sub  # no submissions yet for this assignment
    
    hours = 0
    due_date = assignment.due_date
    last_submission_time = sub.submitted_at
    if last_submission_time > due_date
      hours = (last_submission_time - due_date) / 3600  # rounded in hours
    end
    
    return (hours / 24.0).ceil
  end
  
  def self.get_version(time)
    time.strftime("%m-%d-%Y-%H-%M-%S")
  end
  
end
