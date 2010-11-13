require 'fileutils' # FileUtils used here

# Handle for getting student submissions.  Actual instance depend 
# on whether an assignment is a group or individual assignment.
# Use Assignment.submission_by(user) to retrieve the correct submission.
class Submission < ActiveRecord::Base
  after_create :create_result
  before_validation_on_create :bump_old_submissions

  validates_numericality_of :submission_version, :only_integer => true
  belongs_to :grouping
  has_one    :result, :dependent => :destroy
  has_many   :submission_files, :dependent => :destroy
  has_many   :annotations, :through => :submission_files
  has_many   :test_results, :dependent => :destroy
  belongs_to :remark_result, :class_name => "Result"

  validates_associated :remark_result
  
  def self.create_by_timestamp(grouping, timestamp)
     if !timestamp.kind_of? Time
       raise "Expected a timestamp of type Time"
     end
     repo = grouping.group.repo
     revision = repo.get_revision_by_timestamp(timestamp)
     submission = self.generate_new_submission(grouping, revision)
     repo.close
     return submission
  end
  
  def self.create_by_revision_number(grouping, revision_number)
    repo = grouping.group.repo
    revision = repo.get_revision(revision_number)
    submission = self.generate_new_submission(grouping, revision)
    repo.close
    return submission
  end
  
  def self.generate_new_submission(grouping, revision)
     new_submission = Submission.new
     new_submission.grouping = grouping
     new_submission.submission_version = 1
     new_submission.submission_version_used = true
     new_submission.revision_timestamp = revision.timestamp
     new_submission.revision_number = revision.revision_number
     
     new_submission.transaction do
       begin
         new_submission.populate_with_submission_files(revision)
       rescue Repository::FileDoesNotExist => e
         #populate the submission with no files instead of raising an exception
       end
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

  #=== Description
  # Helper class method to find a submission by providing a group_name and
  # and an assignment short identifier.
  #=== Returns
  # nil if no such submission exists.
  def self.get_submission_by_group_and_assignment(group_n, ass_si)
    assignment = Assignment.find_by_short_identifier(ass_si)
    group = Group.find_by_group_name(group_n)
    if !assignment.nil? && !group.nil?
      grouping = group.grouping_for_assignment(assignment.id)
      return grouping.current_submission_used
    else
      return nil
    end
  end
  
  private
  
  def create_result
    result = Result.new
    self.result = result
    result.marking_state = Result::MARKING_STATES[:unmarked]
    result.save
  end

  # Bump any old Submissions down the line and ensure no submission has
  # submission_version_used == true
  def bump_old_submissions
     while grouping.reload.has_submission?
       old_submission = grouping.current_submission_used
       if self.submission_version.nil? or self.submission_version <= old_submission.submission_version
         self.submission_version = old_submission.submission_version + 1
       end
       old_submission.submission_version_used = false
       old_submission.save
       old_result = old_submission.result
       old_result.released_to_students = false
       old_result.save
     end
  end

end
