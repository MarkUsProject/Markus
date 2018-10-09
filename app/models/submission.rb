require 'fileutils' # FileUtils used here

# Handle for getting student submissions.  Actual instance depend
# on whether an assignment is a group or individual assignment.
class Submission < ApplicationRecord
  after_create :create_result
  before_validation :bump_old_submissions, on: :create

  validates_numericality_of :submission_version, only_integer: true
  validate :max_number_of_results
  belongs_to :grouping

  has_many   :results, -> { order :created_at },
             dependent: :destroy

  has_many   :non_pr_results, -> { where(peer_review_id: nil).order(:created_at) },
             class_name: 'Result'

  has_one    :current_result, -> { where(peer_review_id: nil).order(created_at: :desc) },
             class_name: 'Result'

  has_one    :submitted_remark, -> { where.not remark_request_submitted_at: nil },
             class_name: 'Result'

  has_many   :submission_files, dependent: :destroy
  has_many   :annotations, through: :submission_files
  has_many   :test_runs, -> { order 'created_at DESC' }, dependent: :nullify
  has_many   :feedback_files, dependent: :destroy


  def self.create_by_timestamp(grouping, timestamp)
     unless timestamp.kind_of? Time
       raise 'Expected a timestamp of type Time'
     end
     submission = grouping.group.access_repo do |repo|
       path = grouping.assignment.repository_folder
       revision = repo.get_revision_by_timestamp(timestamp, path)
       generate_new_submission(grouping, revision)
     end
     submission
  end

  def self.create_by_revision_identifier(grouping, revision_identifier)
    submission = grouping.group.access_repo do |repo|
      revision = repo.get_revision(revision_identifier)
      generate_new_submission(grouping, revision)
    end
    submission
  end

  def self.generate_new_submission(grouping, revision)
    Submission.transaction do
      new_submission = Submission.new
      new_submission.grouping = grouping
      new_submission.submission_version = 1
      new_submission.submission_version_used = true
      new_submission.revision_timestamp = revision&.server_timestamp
      new_submission.revision_identifier = revision&.revision_identifier
      unless revision.nil?
        begin
          new_submission.populate_with_submission_files(revision)
        rescue Repository::FileDoesNotExist
          # populate the submission with no files instead of raising an exception
        end
      end
      new_submission.save!
      new_submission
    end
  end

  # Returns the original result.
  def get_original_result
    non_pr_results.first
  end

  def remark_result
    if remark_request_timestamp.nil? || non_pr_results.length < 2
      nil
    else
      non_pr_results.last
    end
  end

  def remark_result_id
    remark_result.try(:id)
  end

  # Returns the latest result.
  def get_latest_result
    if !submitted_remark.nil?
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

  # Sets marks when automated tests are run
  def set_autotest_marks
    test_run = test_runs.first
    return if test_run.nil? || test_run.test_script_results.empty?
    result = get_latest_result
    complete_marks = true
    if result.marks.empty? # can happen if a criterion is created after collection
      result.create_marks
    end
    result.marks.each do |mark|
      test_scripts = mark.markable.test_scripts
      if test_scripts.size == 0 # there's at least one manually-assigned mark
        complete_marks = false
        next
      end
      all_marks_earned = 0.0
      all_marks_total = 0.0
      test_scripts.each do |test_script|
        res = test_run.test_script_results.find_by(test_script: test_script)
        all_marks_earned += res&.marks_earned || 0.0
        all_marks_total += res&.marks_total || 0.0
      end
      if all_marks_earned == 0 || all_marks_total == 0
        final_mark = 0.0
      elsif all_marks_earned > all_marks_total
        final_mark = mark.markable.max_mark
      else
        final_mark = (all_marks_earned / all_marks_total * mark.markable.max_mark).round(2)
        if mark.markable.instance_of? RubricCriterion
          # find the nearest mark associated to a level
          nearest_mark = (final_mark / mark.markable.weight.to_f).round * mark.markable.weight
          final_mark = nearest_mark
        end
      end
      mark.mark = final_mark
      mark.save
    end

    # all marks are set by tests, can set the marking state to complete
    if complete_marks
      result.marking_state = Result::MARKING_STATES[:complete]
      result.save
    end
    # marking state just set, or it was already complete (tests are overwriting some marks)
    if result.marking_state == Result::MARKING_STATES[:complete]
      result.submission.assignment.assignment_stat.refresh_grade_distribution
      result.submission.assignment.update_results_stats
    end
  end

  def test_script_results_hash
    TestScriptResult
      .joins(:test_script, :test_results, test_run: [:user])
      .where(test_runs: { submission_id: id })
      .pluck_to_hash(:created_at, :user_id, :name, :file_name, :user_name,
                     :actual_output, :completion_status, :extra_info,
                     'test_results.marks_earned', 'test_results.marks_total')
      .each { |g| g['created_at_user_name'] = "#{I18n.l(g[:created_at])} (#{g[:user_name]})" }
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
    !submitted_remark.nil?
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

  def self.get_submission_by_group_id_and_assignment_id(group_id, assignment_id)
    group = Group.find(group_id)
    grouping = group.grouping_for_assignment(assignment_id)
    grouping.current_submission_used
  end

  def self.get_submission_by_grouping_id_and_assignment_id(grouping_id,
                                                        assignment_id)
    assignment = Assignment.find(assignment_id)
    grouping = assignment.groupings.find(grouping_id)
    grouping.current_submission_used
  end

  def make_remark_result
    remark = results.create(
      marking_state: Result::MARKING_STATES[:incomplete],
      remark_request_submitted_at: Time.zone.now)

    # populate remark result with old marks
    original_result = get_original_result
    remark_assignment = remark.submission.grouping.assignment

    original_result.extra_marks.each do |extra_mark|
      remark.extra_marks.create(result: remark,
                                created_at: Time.zone.now,
                                description: extra_mark.description,
                                extra_mark: extra_mark.extra_mark,
                                unit: extra_mark.unit)
    end

    remark_assignment.get_criteria(:ta).each do |criterion|
      remark_mark = Mark.where(markable: criterion, result_id: remark.id)
      original_mark = Mark.where(markable: criterion, result_id: original_result.id)
      remark_mark.first.update!(mark: original_mark.first.mark)
    end

    remark.save
  end

  private

  def create_result
    result = Result.new
    results << result
    result.marking_state = Result::MARKING_STATES[:incomplete]
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

  def max_number_of_results
    results.size < 3
  end
end
