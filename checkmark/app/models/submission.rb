class Submission < ActiveRecord::Base
  
  belongs_to  :assignment
  belongs_to  :user
  belongs_to  :group
  has_many    :submission_files
  
  belongs_to  :assignment_file  # TODO deprecated
  # TODO cannot submit if pending
  # TODO test distinct keywords
  
  # Handles file submissions
  def submit(user, file, submission_time)
    filename = file.original_filename
    
    # create a backup if file already exists
    filepath = File.join(submit_dir, filename)
    create_backup(filename) if File.exists?(filepath)
    
    # create a submission_file record
    submission_file = submission_files.create do |f|
      f.user = user
      f.filename = file.original_filename
      f.submitted_at = submission_time
    end
    
    # upload file contents to file system
    File.open(filepath, "wb") { |f| f.write(file.read) } if submission_file.save
    return submission_file
  end
  
  # Delete all records of filename in submissions and store in backup folder
  def remove_file(filename)
    _adir = submit_dir
    backup_dir = File.join(_adir, "BACKUP")
    FileUtils.mkdir(backup_dir)
    
    source_file = File.join(_adir, filename)
    dest_file = File.join(backup_dir, filename)
    FileUtils.mv(source_file, dest_file, :force => true)
    
    submission_files.destroy_all(["filename = ?", filename])
  end
  
  # Moves the file to a folder with the last submission date
  #   filepath - absolute path of the file
  def create_backup(filename)
    ts = last_submission_time_by_filename(filename)
    timestamp = ts.strftime("%m-%d-%Y-%H-%M-%S")
    
    # create backup directory and move file
    backup_dir = File.join(submit_dir, timestamp)
    FileUtils.mkdir(backup_dir)
    dest_file = File.join(backup_dir, filename)
    source_file = File.join(submit_dir, filename)
    FileUtils.mv(source_file, dest_file, :force => true)
  end
  
  # Returns the submission directory for this user
  def submit_dir
    path = File.join(SUBMISSIONS_PATH, assignment.name, owner.user_name)
    FileUtils.mkdir_p(path)
    return path
  end
  
  
  # Query functions -------------------------------------------------------
  
  # Returns an array of distinct submitted file names.
  def submitted_filenames
    reqfiles = assignment.assignment_files.map { |af| af.filename } || []
    result = []
    fnames = submission_files.maximum(:submitted_at, :group => :filename)
    fnames.each do |filename, submitted_at|
      result << submission_files.find_by_filename_and_submitted_at(filename, submitted_at)
      reqfiles.delete(filename) # required file has already been submitted
    end
    
    # convert required files to a SubmissionFile instance 
    reqfiles = reqfiles.map do |af| 
      SubmissionFile.new(:filename => af, :status => "unsubmitted")
    end
    return reqfiles.concat(result)
  end
  
  # Returns the last submission time with the given filename
  def last_submission_time_by_filename(filename)
    conditions = ["filename = ?", filename]
    # need to convert to local time
    submission_files.maximum(:submitted_at, :conditions => conditions).getlocal
  end
  
  # Returns the last submission time for any submitted file
  def last_submission_time
    # need to convert to local time
    submission_files.maximum(:submitted_at).getlocal
  end
  
  # array of required filenames that has not yet been submitted
  def unsubmitted_files
   
  end
  
  # DEPRECATED -------------------------------------------------------------
  
  # returns assignment files submitted by this group
  # TODO deprecated: only used in submit()
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
  
  
  # Returns last submission time for this user in a group for an assignment.
  # returns beginning of epoch time if user has not submitted anything
  # If assignment is individual group number is the user id
  def self.last_submission(user, group_number, assignment)
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
    return sub ? sub.submitted_at : Time.at(0)
  end
  
  # get number of used grace days used given last submission time for this assignment
  def self.get_used_grace_days(last_submission_time, assignment)
    hours = 0
    due_date = assignment.due_date
    if last_submission_time > due_date
      hours = (last_submission_time - due_date) / 3600.0  # in hours
    end
    
    return (hours / 24.0).ceil
  end
  
  def self.get_version(time)
    time.strftime("%m-%d-%Y-%H-%M-%S")
  end
  
end
