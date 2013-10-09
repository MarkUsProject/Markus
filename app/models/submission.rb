require 'fileutils' # FileUtils used here

# Handle for getting student submissions.  Actual instance depend
# on whether an assignment is a group or individual assignment.
# Use Assignment.submission_by(user) to retrieve the correct submission.
class Submission < ActiveRecord::Base
  after_create :create_result
  before_validation(:bump_old_submissions, :on => :create)

  validates_numericality_of :submission_version, :only_integer => true
  belongs_to :grouping
  has_many   :results, :dependent => :destroy
  has_many   :submission_files, :dependent => :destroy
  has_many   :annotations, :through => :submission_files
  has_many   :test_results, :dependent => :destroy

  def self.create_by_timestamp(grouping, timestamp)
     unless timestamp.kind_of? Time
       raise 'Expected a timestamp of type Time'
     end
     repo = grouping.group.repo
     path = grouping.assignment.repository_folder
     revision = repo.get_revision_by_timestamp(timestamp, path)
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

  # returns the original result
  def get_original_result
    if self.remark_result_id.nil?
      Result.first(:conditions => ['submission_id = ?', self.id])
    else
      Result.first(:conditions => ['submission_id = ? AND id != ?',
                                   self.id, self.remark_result_id])
    end
  end

  # returns the remark result if exists, returns nil if does not exist
  def get_remark_result
    Result.first(:conditions => ['id = ?', self.remark_result_id])
  end

  # returns the latest result - remark result if exists and submitted, else original result
  def get_latest_result
    if self.remark_submitted?
      self.get_remark_result
    else
      self.get_original_result
    end
  end

  # returns the latest completed result - note: will return nil if there is no completed result
  def get_latest_completed_result
    if self.remark_submitted? && self.get_remark_result.marking_state == Result::MARKING_STATES[:complete]
      return self.get_remark_result
    end
    if self.get_original_result.marking_state == Result::MARKING_STATES[:complete]
      return self.get_original_result
    end
    nil
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
      f.submission_file_status = 'late' if assignment.due_date < submission_time
    end

    # upload file contents to file system
    File.open(filepath, 'wb') { |f| f.write(file.read) } if submission_file.save
    submission_file
  end

  # Delete all records of filename in submissions and store in backup folder
  # (for now, called "BACKUP")
  def remove_file(filename)
    # get all submissions for this filename
    files = submission_files.all(:conditions => ['filename = ?', filename])
    return unless files && !files.empty?
    files.each { |f| f.destroy }  # destroy all records first

    _adir = submit_dir
    backup_dir = File.join(_adir, 'BACKUP')
    FileUtils.mkdir_p(backup_dir)

    source_file = File.join(_adir, filename)
    dest_file = File.join(backup_dir, filename)
    FileUtils.mv(source_file, dest_file, :force => true)
  end


  # Query functions -------------------------------------------------------
  # Figure out which assignment this submission is for
  def assignment
    self.grouping.assignment
  end

  def has_result?
    results.any?
  end

  # Does this submission have a remark result?
  def has_remark?
    !self.remark_result_id.nil?
  end

  # Does this submission have a remark request submitted?
  # remark_results in 'unmarked' state have not been submitted by the student yet (just saved)
  # Submitted means that the remark request can be viewed by instructors and TAs and is no
  #   longer editable by the student.
  # Saved means that the remark request cannot be viewed by instructors or TAs yet and
  #   the student can still make changes to the request details.
  def remark_submitted?
    self.has_remark? && self.get_remark_result.marking_state != Result::MARKING_STATES[:unmarked]
  end

  # Helper methods
  def populate_with_submission_files(revision, path='/')
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
      return grouping.current_submission_used if !grouping.nil?
    end
    return nil
  end

  def create_remark_result
    remark_result = Result.new
    results << remark_result
    remark_result.marking_state = Result::MARKING_STATES[:unmarked]
    remark_result.submission_id = self.id
    remark_result.save
    # link remark result id to submission - must be done after remark result is saved (so it has an id)
    self.remark_result_id = remark_result.id
    self.save

    # populate remark result with old marks
    original_result = get_original_result

    old_extra_marks = original_result.extra_marks
    old_extra_marks.each do |old_extra_mark|
      remark_extra_mark = ExtraMark.new(old_extra_mark.attributes.merge(
        {:result_id => self.remark_result_id, :created_at => Time.zone.now}))
      remark_extra_mark.save(:validate => false)
      remark_result.extra_marks << remark_extra_mark
    end

    old_marks = original_result.marks
    old_marks.each do |old_mark|
      remark_mark = Mark.new(old_mark.attributes.merge(
        {:result_id => self.remark_result_id, :created_at => Time.zone.now}))
      remark_mark.save(:validate => false)
      remark_result.marks << remark_mark
    end
  end

  private

  def create_result
    result = Result.new
    results << result
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
       old_result = old_submission.get_original_result
       old_result.released_to_students = false
       old_result.save
     end
  end

end
