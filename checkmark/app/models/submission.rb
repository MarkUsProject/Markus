
# Handle for getting student submissions.  Actual instance depend 
# on whether an assignment is a group or individual assignment.
# Use Assignment.submission_by(user) to retrieve the correct submission.
class Submission < ActiveRecord::Base
  
  belongs_to  :assignment
  belongs_to  :user
  belongs_to  :group
  has_many    :submission_files, :dependent => :destroy
  has_many    :annotations, :through => :submission_files
  belongs_to  :assignment_file
  
  # For group submissions, actions here must only be accessible to members
  # that has inviter or accepted status. This check is done when fetching 
  # the user or group submission from an assignment (see controller).
  
  # Handles file submissions. Late submissions have a status of "late"
  def submit(user, file, submission_time, sdir=SUBMISSIONS_PATH)
    filename = file.original_filename
    
    # create a backup if file already exists
    dir = submit_dir(sdir)
    filepath = File.join(dir, filename)
    create_backup(filename, sdir) if File.exists?(filepath)
    
    # create a submission_file record
    submission_file = submission_files.create do |f|
      f.user = user
      f.filename = file.original_filename
      f.submitted_at = submission_time
      f.status = "late" if assignment.due_date < submission_time
    end
    
    # upload file contents to file system
    File.open(filepath, "wb") { |f| f.write(file.read) } if submission_file.save
    return submission_file
  end
  
  # Delete all records of filename in submissions and store in backup folder
  # (for now, called "BACKUP")
  def remove_file(filename)
    # get all submissions for this filename
    files = submission_files.all(:conditions => ["filename = ?", filename])
    return unless files && !files.empty?
    files.each { |f| f.destroy }  # destroy all records first
    
    _adir = submit_dir
    backup_dir = File.join(_adir, "BACKUP")
    FileUtils.mkdir_p(backup_dir)
    
    source_file = File.join(_adir, filename)
    dest_file = File.join(backup_dir, filename)
    FileUtils.mv(source_file, dest_file, :force => true)
  end
  
  
  # Query functions -------------------------------------------------------
  
  # Returns an array of distinct submitted file names, including required 
  # files that has not yet been submitted (with 'unsubmitted' status).
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
  
  # Returns the last submission time with the given filename.  
  # Returns epoch time if no such file exists.
  def last_submission_time_by_filename(filename)
    conditions = ["filename = ?", filename]
    # need to convert to local time
    ts = submission_files.maximum(:submitted_at, :conditions => conditions)
    return ts ? ts.getlocal : ts  # return nil if no such file exists
  end
  
  # Returns the submission directory for this user
  def submit_dir(sdir=SUBMISSIONS_PATH)
    path = File.join(sdir, assignment.name, owner.user_name)
    FileUtils.mkdir_p(path)
    return path
  end

  # Helper methods
  
  protected
  
  # Moves the file to a folder with the last submission date
  #   filepath - absolute path of the file
  def create_backup(filename, sdir=SUBMISSIONS_PATH)
    ts = last_submission_time_by_filename(filename)
    return unless ts
    timestamp = ts.strftime("%m-%d-%Y-%H-%M-%S")
    
    # create backup directory and move file
    backup_dir = File.join(submit_dir(sdir), timestamp)
    FileUtils.mkdir_p(backup_dir)
    dest_file = File.join(backup_dir, filename)
    source_file = File.join(submit_dir, filename)
    FileUtils.mv(source_file, dest_file, :force => true)
  end
  
end
