class Submission < ActiveRecord::Base
  
  belongs_to  :assignment_file
  
  
  # TODO cannot submit if pending
  # TODO if assignment is individual, user_id is used as group_number
  # TODO test distinct keywords
  
  # returns assignment files submitted by this group
  def self.submitted_files(group_number)
    # TODO filter out multiple submissions of the same file.
    return nil unless group_number
    all(:include => :assignment_file, :select => "DISTINCT assignment_file_id",
      :conditions => ["group_number = ?", group_number])
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
  
end
