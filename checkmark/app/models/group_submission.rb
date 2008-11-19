
class GroupSubmission < Submission
  
  belongs_to  :group
  
  # Return the user with the inviter status for this group
  def owner
    group.inviter
  end
  
  # Change the owner of this group submission 
  # by renaming submission folder to this new owner
  def owner=(member, sdir=SUBMISSIONS_PATH)
    old_path = File.join(sdir, assignment.name, owner.user_name)
    return unless File.exist?(old_path)  # no need to rename
    new_path = File.join(sdir, assignment.name, member.user_name)
    File.rename(old_path, new_path)
  end
  
end
