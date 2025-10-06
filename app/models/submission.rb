require 'fileutils' # FileUtils used here

# Handle for getting student submissions.  Actual instance depend
# on whether an assignment is a group or individual assignment.
class Submission < ApplicationRecord
  before_validation :bump_old_submissions, on: :create
  after_create :create_result

  validates :submission_version_used, inclusion: { in: [true, false] }
  validates :submission_version, numericality: { only_integer: true }
  validate :max_number_of_results
  belongs_to :grouping

  has_many :results, -> { order :created_at },
           dependent: :destroy,
           inverse_of: :submission

  has_many :non_pr_results, -> { left_outer_joins(:peer_reviews).where('peer_reviews.id': nil).order(:created_at) },
           class_name: 'Result',
           inverse_of: :submission

  has_one :current_result, -> {
                             left_outer_joins(:peer_reviews).where('peer_reviews.id': nil)
                                                            .order(created_at: :desc)
                           },
          class_name: 'Result',
          inverse_of: :submission

  has_one :submitted_remark, -> { where.not remark_request_submitted_at: nil },
          class_name: 'Result',
          inverse_of: :submission

  has_many :submission_files, dependent: :destroy
  has_many :annotations, through: :submission_files
  has_many :test_runs, -> { order(created_at: :desc) }, dependent: :nullify, inverse_of: :submission
  has_many :test_group_results, through: :test_runs
  has_many :feedback_files, dependent: :destroy

  has_one :course, through: :grouping

  def self.create_by_timestamp(grouping, timestamp)
    unless timestamp.is_a? Time
      raise 'Expected a timestamp of type Time'
    end
    grouping.access_repo do |repo|
      path = grouping.assignment.repository_folder
      revision = repo.get_revision_by_timestamp(timestamp, path)
      generate_new_submission(grouping, revision)
    end
  end

  def self.create_by_revision_identifier(grouping, revision_identifier)
    grouping.access_repo do |repo|
      revision = repo.get_revision(revision_identifier)
      generate_new_submission(grouping, revision)
    end
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
        SubmissionFile.transaction do
          new_submission.is_empty = !new_submission.populate_with_submission_files(revision)
        rescue Repository::FileDoesNotExist
          # populate the submission with no files instead of raising an exception
          raise ActiveRecord::Rollback
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

  # Returns a remark result that may or may not have been submitted.
  # If you want the submitted remark result then the submitted_remark
  # association should be used instead.
  def remark_result
    if remark_request_timestamp.nil? || non_pr_results.length < 2
      nil
    else
      non_pr_results.last
    end
  end

  # Returns the latest result.
  def get_latest_result
    if !submitted_remark.nil?
      remark_result
    else
      get_original_result
    end
  end

  # Returns the latest result that has been released to students
  # If no results are released (because a remark request has been submitted but not released)
  # then return the original result instead since that one should be visible while the remark
  # request is being processed
  def get_visible_result
    non_pr_results.reorder(id: :desc).where(released_to_students: true).first || get_original_result
  end

  # Sets marks when automated tests are run
  def set_autotest_marks
    test_run = test_runs.first
    return if test_run.nil? || test_run.test_group_results.empty?

    result = get_latest_result
    complete_marks = true
    result.create_marks # creates marks for any new criteria that may have just been added
    result.marks.each do |mark|
      test_groups = mark.criterion.test_groups
      test_group_results = test_run.test_group_results.where(test_group_id: test_groups.ids)
      # don't update mark if there are no results, or if there was an error
      if test_group_results.empty? || test_group_results.exists?(error_type: TestGroupResult::ERROR_TYPE.values)
        complete_marks = false
        next
      end

      all_marks_earned = 0.0
      all_marks_total = 0.0
      test_group_results.each do |res|
        all_marks_earned += res.marks_earned
        all_marks_total += res.marks_total
      end
      if all_marks_earned == 0 || all_marks_total == 0
        final_mark = 0.0
      elsif all_marks_earned >= all_marks_total
        final_mark = mark.criterion.max_mark
      elsif mark.criterion.is_a? CheckboxCriterion
        final_mark = 0
      else
        final_mark = (all_marks_earned / all_marks_total * mark.criterion.max_mark).round(2)
        if mark.criterion.instance_of? RubricCriterion
          # find the nearest mark associated to a level
          nearest_mark = mark.criterion.level_with_mark_closest_to(final_mark).mark
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
  end

  def test_group_results_hash
    TestGroupResult
      .joins(:test_group, :test_results, test_run: [:user])
      .where(test_runs: { submission_id: id })
      .pluck_to_hash(:created_at, :user_id, :user_name, 'test_group.name',
                     :output, :status, :extra_info, 'test_results.name',
                     'test_results.marks_earned', 'test_results.marks_total')
      .each { |g| g['created_at_user_name'] = "#{I18n.l(g[:created_at])} (#{g[:user_name]})" }
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

  # Create submission files for this submission. Do not create submission
  # files that are one of the reserved filenames for a given repository type.
  #
  # Return True if at least one submission file was created.
  def populate_with_submission_files(revision, path = '/')
    # Remember that assignments have folders within repositories - these
    # will be "spoofed" as root...
    if path == '/'
      path = assignment.repository_folder
    end

    files_added = false
    # First, go through directories...
    directories = revision.directories_at_path(path)
    directories.each_value do |directory|
      files_added = populate_with_submission_files(revision, File.join(path, directory.name))
    end
    files = revision.files_at_path(path)
    files.each do |filename, file|
      next if Repository.get_class.internal_file_names.include? filename

      files_added = true
      new_file = SubmissionFile.new
      new_file.submission = self
      new_file.filename = file.name
      new_file.path = file.path
      new_file.save
    end
    files_added
  end

  def self.get_submission_by_group_id_and_assignment_id(group_id, assignment_id)
    group = Group.find(group_id)
    grouping = group.grouping_for_assignment(assignment_id)
    grouping.current_submission_used
  end

  def make_remark_result
    remark = results.create(
      marking_state: Result::MARKING_STATES[:incomplete],
      remark_request_submitted_at: Time.current
    )

    # populate remark result with old marks
    original_result = get_original_result
    remark_assignment = remark.submission.grouping.assignment

    original_result.extra_marks.each do |extra_mark|
      remark.extra_marks.create(result: remark,
                                created_at: Time.current,
                                description: extra_mark.description,
                                extra_mark: extra_mark.extra_mark,
                                unit: extra_mark.unit)
    end

    remark_assignment.ta_criteria.each do |criterion|
      remark_mark = remark.marks.find_by(criterion: criterion)
      original_mark = original_result.marks.find_by(criterion: criterion)
      remark_mark.update!(mark: original_mark.mark, override: original_mark.override)
    end

    remark.save
  end

  def copy_grading_data(old_submission)
    return if old_submission.blank?

    # copy submission-wide data to this submission
    old_submission.feedback_files.each do |feedback_file|
      feedback_file_dup = feedback_file.dup
      feedback_file_dup.update!(submission_id: self.id)
    end

    old_submission.test_runs.each do |test_run|
      test_run_dup = test_run.dup
      test_run_dup.update!(submission_id: self.id)

      test_run.test_group_results.each do |test_group_result|
        test_group_result_dup = test_group_result.dup
        test_group_result_dup.update!(test_run_id: test_run_dup.id)

        test_group_result.test_results.each do |test_result|
          test_result_dup = test_result.dup
          test_result_dup.update!(test_group_result_id: test_group_result_dup.id)
        end

        test_group_result.feedback_files.each do |feedback_file|
          feedback_file_dup = feedback_file.dup
          feedback_file_dup.update!(test_group_result_id: test_group_result_dup.id)
        end
      end
    end

    self.get_original_result.copy_grading_data(old_submission.get_original_result)

    # copy over any unsubmitted or submitted remark request
    self.update(remark_request: old_submission.remark_request,
                remark_request_timestamp: old_submission.remark_request_timestamp)

    # if there's already a remark result created as well, we need to copy that
    # too
    old_remark_result = old_submission.remark_result
    if old_remark_result.present?
      self.create_result
      self.remark_result.copy_grading_data(old_remark_result)
    end
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
      if self.submission_version.nil? || (self.submission_version <= old_submission.submission_version)
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
