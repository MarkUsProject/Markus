require 'fileutils' # FileUtils used here

# Handle for getting student submissions.  Actual instance depend
# on whether an assignment is a group or individual assignment.
class Submission < ActiveRecord::Base
  after_create :create_result
  before_validation :bump_old_submissions, on: :create

  validates_numericality_of :submission_version, only_integer: true
  belongs_to :grouping

  has_many   :results, dependent: :destroy
  belongs_to :remark_result, class_name: 'Result', dependent: :destroy
  has_many   :submission_files, dependent: :destroy
  has_many   :annotations, through: :submission_files
  has_many   :test_results, dependent: :destroy
  has_many   :test_script_results, dependent: :destroy
  has_many   :feedback_files, dependent: :destroy


  def self.create_by_timestamp(grouping, timestamp)
     unless timestamp.kind_of? Time
       raise 'Expected a timestamp of type Time'
     end
     repo = grouping.group.repo
     path = grouping.assignment.repository_folder
     revision = repo.get_revision_by_timestamp(timestamp, path)
     submission = self.generate_new_submission(grouping, revision)
     repo.close
     submission
  end

  def self.create_by_revision_number(grouping, revision_number)
    repo = grouping.group.repo
    revision = repo.get_revision(revision_number)
    submission = self.generate_new_submission(grouping, revision)
    repo.close
    submission
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
      rescue Repository::FileDoesNotExist
        # populate the submission with no files instead of raising an exception
      end
      new_submission.save
    end
    new_submission
  end

  # Returns the original result.
  def get_original_result
    Result.where(submission_id: id).order(:created_at).first
  end

  # Returns the latest result.
  def get_latest_result
    if remark_submitted?
      remark_result
    else
      get_original_result
    end
  end

  # Returns the latest completed result.
  def get_latest_completed_result
    if remark_submitted? &&
       remark_result.marking_state == Result::MARKING_STATES[:complete]
      remark_result
    elsif get_original_result.marking_state == Result::MARKING_STATES[:complete]
      get_original_result
    else
      nil
    end
  end

  # Sets marks for associated criteria
  def set_mark_by_criteria(grouping, assignment_id)
    result = grouping.group.grouping_for_assignment(assignment_id)
                 .current_submission_used
                 .get_latest_result

    test_scripts = TestScript.where(assignment_id: assignment_id)

    test_scripts.each do |test_script|

      matched_criteria = RubricCriterion
                             .where(rubric_criterion_name: test_script.associated_criterion,
                                    assignment_id: assignment_id)
      matched_criteria.concat(FlexibleCriterion
                                  .where(flexible_criterion_name: test_script.associated_criterion,
                                         assignment_id: assignment_id))

      test_result = TestScriptResult.where(:test_script_id => test_script.id, :grouping_id => grouping.id).last

      matched_criteria.each do |crit|
        mark_to_change = result.marks.find_or_create_by(
            markable_id: crit.id,
            markable_type: crit.class.name)
        mark_to_change.mark = test_result.marks_earned
        mark_to_change.save
      end
    end
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
    files = submission_files.where(filename: filename)
    return unless files && !files.empty?
    files.each { |f| f.destroy }  # destroy all records first

    _adir = submit_dir
    backup_dir = File.join(_adir, 'BACKUP')
    FileUtils.mkdir_p(backup_dir)

    source_file = File.join(_adir, filename)
    dest_file = File.join(backup_dir, filename)
    FileUtils.mv(source_file, dest_file, force: true)
  end


  # Query functions -------------------------------------------------------
  # Figure out which assignment this submission is for
  def assignment
    self.grouping.assignment
  end

  def has_result?
    results.any?
  end

  # Returns whether this submission has a remark result.
  def has_remark?
    !remark_result.nil?
  end

  # Returns whether this submission has a remark request that has been
  # submitted to instructors or TAs.
  def remark_submitted?
    has_remark? &&
      remark_result.marking_state != Result::MARKING_STATES[:unmarked]
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
    assignment = Assignment.where(short_identifier: ass_si).first
    group = Group.where(group_name: group_n).first
    if !assignment.nil? && !group.nil?
      grouping = group.grouping_for_assignment(assignment.id)
      grouping.current_submission_used if !grouping.nil?
    end
  end

  def self.get_submission_by_grouping_id_and_assignment_id(grouping_id,
                                                        assignment_id)
    assignment = Assignment.find(assignment_id)
    grouping = assignment.groupings.find(grouping_id)
    grouping.current_submission_used
  end

  def make_remark_result
    remark = create_remark_result(
      marking_state: Result::MARKING_STATES[:unmarked],
      submission_id: id)
    self.save

    # populate remark result with old marks
    original_result = get_original_result

    original_result.extra_marks.each do |extra_mark|
      remark.extra_marks.create(result: remark,
                                created_at: Time.zone.now,
                                markable_id: extra_mark.markable_id,
                                mark: extra_mark.mark,
                                markable_type: extra_mark.markable_type)
    end

    original_result.marks.each do |mark|
      remark_result.marks.create(result: remark,
                                 created_at: Time.zone.now,
                                 markable_id: mark.markable_id,
                                 mark: mark.mark,
                                 markable_type: mark.markable_type)
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
