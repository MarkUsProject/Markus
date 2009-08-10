require 'fileutils' # FileUtils used here

# Handle for getting student submissions.  Actual instance depend 
# on whether an assignment is a group or individual assignment.
# Use Assignment.submission_by(user) to retrieve the correct submission.
class Submission < ActiveRecord::Base
  after_create :create_result

  validates_numericality_of :submission_version, :only_integer => true
  belongs_to :grouping
  has_one    :result, :dependent => :destroy
  has_many    :submission_files, :dependent => :destroy
  has_many    :annotations, :through => :submission_files
  
  def self.create_by_timestamp(grouping, timestamp)
     if !timestamp.kind_of? Time
       raise "Expected a timestamp of type Time"
     end
     repo = grouping.group.repo
     revision = repo.get_revision_by_timestamp(timestamp)
     return self.generate_new_submission(grouping, revision)    
  end
  
  def self.create_by_revision_number(grouping, revision_number)
    repo = grouping.group.repo
    revision = repo.get_revision(revision_number)
    return self.generate_new_submission(grouping, revision)
  end
  
  def self.generate_new_submission(grouping, revision)
     new_submission = Submission.new
     new_submission.grouping = grouping
     new_submission.submission_version = 1
     new_submission.submission_version_used = true
     new_submission.revision_timestamp = revision.timestamp
     new_submission.revision_number = revision.revision_number

     # Bump any old Submissions down the line
     new_submission.transaction do
       if grouping.has_submission?
         old_submission = grouping.get_submission_used
         new_submission.submission_version = old_submission.submission_version + 1
         old_submission.submission_version_used = false
         old_submission.save
         old_result = old_submission.result
         old_result.released_to_students = false
         old_result.save
       end
       new_submission.populate_with_submission_files(revision)
       new_submission.save
     end
     return new_submission
  end
  
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
      f.submission_file_status = "late" if assignment.due_date < submission_time
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
      SubmissionFile.new(:filename => af, :submission_file_status => "unsubmitted")
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
  
  # Figure out which assignment this submission is for
  def assignment
    return self.grouping.assignment
  end

  def has_result?
    return !result.nil?
  end

  # Helper methods
  def populate_with_submission_files(revision, path="/") 
    # Remember that assignments have folders within repositories - these
    # will be "spoofed" as root...
    if path == '/'
      path = assignment.repository_folder
    else
      path = File.join(assignment.repository_folder, path)
    end
    # First, go through directories...
    directories = revision.directories_at_path(path)
    directories.each do |directory_name, directory|
      populate_with_submission_files(revision, File.join(path, directory.name))
    end
    files = revision.files_at_path(path)
    files.each do |filename, file|
      new_file = SubmissionFile.new
      new_file.submission = self
      new_file.filename = file.name
      new_file.path = file.path
      new_file.save
    end 
  end
  
  private
  
  def create_result
    result = Result.new
    self.result = result
    result.marking_state = Result::MARKING_STATES[:unmarked]
    result.save
  end

end
