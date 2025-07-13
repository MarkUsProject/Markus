require 'set'

# Represents a grouping of students working together on a single assignment. This model manages various aspects of the
# grouping's work, such as submissions, peer reviews, test runs, and repository management. A Grouping belongs to a
# group and an assignment and can share a repository with other groupings.
class Grouping < ApplicationRecord
  include SubmissionsHelper

  after_create_commit -> { access_repo } # access the repo to trigger creation of assignment subdirectory
  after_create :reset_starter_file_entries
  after_commit :update_repo_permissions_after_save, on: [:create, :update]

  has_many :memberships, dependent: :destroy
  has_many :student_memberships, -> { order('id') }, inverse_of: :grouping
  has_many :non_rejected_student_memberships,
           -> { where.not(memberships: { membership_status: StudentMembership::STATUSES[:rejected] }) },
           class_name: 'StudentMembership',
           inverse_of: :grouping

  has_many :accepted_student_memberships,
           -> {
             where 'memberships.membership_status' => [StudentMembership::STATUSES[:accepted],
                                                       StudentMembership::STATUSES[:inviter]]
           },
           class_name: 'StudentMembership',
           inverse_of: :grouping

  has_many :pending_student_memberships,
           -> { where 'memberships.membership_status': StudentMembership::STATUSES[:pending] },
           class_name: 'StudentMembership',
           inverse_of: :grouping

  has_many :notes, as: :noteable, dependent: :destroy
  has_many :ta_memberships, class_name: 'TaMembership'
  has_many :tas, through: :ta_memberships, source: :role
  has_many :students, through: :student_memberships, source: :role
  has_many :pending_students,
           class_name: 'Student',
           through: :pending_student_memberships,
           source: :role
  has_many :accepted_students,
           class_name: 'Student',
           through: :accepted_student_memberships,
           source: :role
  has_many :submissions
  has_one :current_submission_used,
          -> { where submission_version_used: true },
          class_name: 'Submission',
          inverse_of: :grouping
  has_one :current_result, through: :current_submission_used
  has_one :submitted_remark, through: :current_submission_used

  has_and_belongs_to_many :tags
  validate :assignments_should_match

  has_many :grace_period_deductions,
           through: :non_rejected_student_memberships

  has_many :test_runs, -> { order(created_at: :desc) }, dependent: :destroy, inverse_of: :grouping
  has_many :test_runs_all_data,
           -> {
             left_outer_joins(role: :user,
                              test_group_results: [:test_group, :test_results])
               .order('test_groups.position', 'test_results.position')
           },
           class_name: 'TestRun',
           inverse_of: :grouping

  has_one :inviter_membership,
          -> { where membership_status: StudentMembership::STATUSES[:inviter] },
          class_name: 'StudentMembership',
          inverse_of: :grouping

  has_one :inviter, source: :role, through: :inviter_membership, class_name: 'Student'
  has_one :section, through: :inviter

  # The following are chained
  # 'peer_reviews' is the peer reviews given for this group via some result
  # 'peer_reviews_to_others' is all the peer reviews this grouping gave to others
  has_many :results, through: :current_submission_used
  has_many :peer_reviews, through: :results
  has_many :peer_reviews_to_others, class_name: 'PeerReview', foreign_key: 'reviewer_id', inverse_of: :reviewer

  scope :approved_groupings, -> { where instructor_approved: true }

  validates :criteria_coverage_count, numericality: { greater_than_or_equal_to: 0 }

  # user association/validation
  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :groupings
  validates_associated :assignment, on: :create

  belongs_to :group
  validates_associated :group

  validate :courses_should_match

  has_one :course, through: :assignment

  validates :is_collected, inclusion: { in: [true, false] }

  validates :test_tokens, presence: true
  validates :test_tokens, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  has_one :extension, dependent: :destroy

  has_many :grouping_starter_file_entries, dependent: :destroy
  has_many :starter_file_entries, through: :grouping_starter_file_entries

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each
  # grouping in a list of groupings specified by +grouping_ids+.
  # The ratio of groupings to ta is specified in +weightings_arr+
  # which is a parallel array to +ta_ids+. The groupings
  # must belong to the given assignment +assignment+.
  def self.randomly_assign_tas(grouping_ids, ta_ids, weightings_arr, assignment)
    # Create a hash of TA's to the number of groups they are supposed to mark
    total = weightings_arr.sum
    weightings = {}
    ta_ids.each_with_index do |group, index|
      weightings[group] = (weightings_arr[index].to_f / total * grouping_ids.length).round
    end

    assign_tas(grouping_ids, ta_ids, assignment) do |grouping_ids_, _|
      # Create 1 TA for each group they are supposed to be assigned to
      ta_ids = ta_ids.sort_by { |ta| weightings[ta] }
      ta_ids_ = ta_ids.flat_map { |ta_id| [ta_id] * weightings[ta_id] }
      # Assign TAs in a round-robin fashion to a list of random groupings.
      grouping_ids_.shuffle.zip(ta_ids_.cycle).reject { |pair| pair.include?(nil) }
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each grouping in
  # a list of groupings specified by +grouping_ids+. The groupings must belong
  # to the given assignment +assignment+.
  def self.assign_all_tas(grouping_ids, ta_ids, assignment)
    assign_tas(grouping_ids, ta_ids, assignment) do |grouping_ids_, ta_ids_|
      # Get the Cartesian product of grouping IDs and TA IDs.
      grouping_ids_.product(ta_ids_)
    end
  end

  def self.assign_by_section(groupings_by_ta, assignment)
    groupings_by_ta.each do |ta_id, grouping_ids|
      assign_tas(grouping_ids, [ta_id], assignment) do |grouping_ids_, ta_ids_|
        # Return the pairs of grouping_ids and the single ta_id
        grouping_ids_.product(ta_ids_)
      end
    end
  end

  # Assigns TAs to groupings using a caller-specified block. The block is given
  # a list of grouping IDs and a list of TA IDs and must return a list of
  # grouping-ID-TA-ID pair that represents the TA assignment.
  #
  #   # Assign the TA with ID 3 to the grouping with ID 1 and the TA
  #   # with ID 4 to the grouping with ID 2.
  #   assign_tas([1, 2], [3, 4], a) do |grouping_ids, ta_ids|
  #     grouping_ids.zip(ta_ids)  # => [[1, 3], [2, 4]]
  #   end
  #
  # The groupings must belong to the given assignment +assignment+.
  def self.assign_tas(grouping_ids, ta_ids, assignment)
    grouping_ids, ta_ids = Array(grouping_ids), Array(ta_ids)
    # Only use IDs that identify existing model instances.
    ta_ids = Ta.where(id: ta_ids).ids
    grouping_ids = Grouping.where(id: grouping_ids).ids
    # Get all existing memberships to avoid violating the unique constraint.
    existing_values = TaMembership
                      .where(grouping_id: grouping_ids, role_id: ta_ids)
                      .pluck(:grouping_id, :role_id)
    # Delegate the assign function to the caller-specified block and remove
    # values that already exist in the database.
    values = yield(grouping_ids, ta_ids) - existing_values

    membership_hash = values.map do |value|
      {
        grouping_id: value[0],
        role_id: value[1],
        type: 'TaMembership'
      }
    end

    Repository.get_class.update_permissions_after do
      unless membership_hash.empty?
        Membership.insert_all(membership_hash)
      end
    end
    update_criteria_coverage_counts(assignment, grouping_ids)
    Criterion.update_assigned_groups_counts(assignment)
  end

  # Unassigns TAs from groupings. +ta_membership_ids+ is a list of TA
  # membership IDs that specifies the unassignment to be done. +grouping_ids+
  # is a list of grouping IDs involved in the unassignment. The memberships
  # and groupings must belong to the given assignment +assignment+.
  def self.unassign_tas(ta_membership_ids, grouping_ids, assignment)
    Repository.get_class.update_permissions_after do
      TaMembership.where(id: ta_membership_ids).delete_all
    end
    update_criteria_coverage_counts(assignment, grouping_ids)
    Criterion.update_assigned_groups_counts(assignment)
  end

  # Updates the +criteria_coverage_count+ field of all groupings specified
  # by +grouping_ids+.
  def self.update_criteria_coverage_counts(assignment, grouping_ids = nil)
    if grouping_ids.nil?
      grouping_ids = assignment.groupings.ids
    end
    return if grouping_ids.empty?

    counts = CriterionTaAssociation
             .from(
               # subquery
               assignment.criterion_ta_associations
                         .joins(ta: :groupings)
                         .where('groupings.id': grouping_ids)
                         .select('criterion_ta_associations.criterion_id',
                                 'groupings.id')
                         .distinct
             )
             .group('subquery.id')
             .count

    grouping_data = Grouping.where(id: grouping_ids).pluck_to_hash.map do |h|
      { **h.symbolize_keys, criteria_coverage_count: counts[h['id'].to_i] || 0 }
    end
    Grouping.upsert_all(grouping_data)
  end

  def get_all_students_in_group
    student_user_names = student_memberships.includes(role: :user).collect { |m| m.role.user_name }
    return I18n.t('groups.empty') if student_user_names.empty?
    student_user_names.join(', ')
  end

  def does_not_share_any_students?(grouping)
    current_student_ids = Set.new
    other_group_student_ids = Set.new
    students.each { |student| current_student_ids.add(student.id) }
    grouping.students.each { |student| other_group_student_ids.add(student.id) }
    !current_student_ids.intersect?(other_group_student_ids)
  end

  def group_name_with_student_user_names
    user_names = get_all_students_in_group
    return group.group_name if user_names == I18n.t('groups.empty')
    "#{group.group_name}: #{user_names}"
  end

  def get_group_name
    group.group_name
  end

  def display_for_note
    "#{assignment.short_identifier}: #{group_name_with_student_user_names}"
  end

  # Query Functions ------------------------------------------------------

  # Returns whether or not a TA is assigned to mark this Grouping
  def has_ta_for_marking?
    ta_memberships.exists?
  end

  def is_collected?
    is_collected
  end

  # Returns true if this user has a pending status for this group;
  # false otherwise, or if user is not in this group.
  def pending?(user)
    membership_status(user) == StudentMembership::STATUSES[:pending]
  end

  # returns whether the user is the inviter of this group or not.
  def is_inviter?(user)
    membership_status(user) == StudentMembership::STATUSES[:inviter]
  end

  # invites each user in 'members' by its user name, to this group
  # If the method is invoked by an instructor, checks on whether the students can
  # be part of the group are skipped.
  def invite(members,
             set_membership_status = StudentMembership::STATUSES[:pending],
             invoked_by_instructor: false)
    # overloading invite() to accept members arg as both a string and a array
    members = [members] unless members.instance_of?(Array) # put a string in an array
    all_errors = []
    members.each do |m|
      m = m.strip
      user = course.students.joins(:user).where(hidden: false).find_by('users.user_name': m)
      begin
        if user.nil?
          raise I18n.t('groups.invite_member.errors.not_found', user_name: m)
        end
        if invoked_by_instructor || self.can_invite?(user)
          self.add_member(user, set_membership_status)
        end
      rescue StandardError => e
        all_errors << e.message
      end
    end
    all_errors
  end

  # Add a new member to base
  def add_member(role, set_membership_status = StudentMembership::STATUSES[:accepted])
    if role.has_accepted_grouping_for?(self.assessment_id) || role.hidden
      nil
    else
      member = StudentMembership.new(role: role, membership_status:
      set_membership_status, grouping: self)
      member.save

      # remove any old deduction for this assignment
      remove_grace_period_deduction(member)

      # Add deductions for the new added member
      deduction = GracePeriodDeduction.new
      deduction.membership = member
      deduction.deduction = self.grace_period_deduction_single
      deduction.save

      member
    end
  end

  # define whether user can be invited in this grouping
  def can_invite?(role)
    if self.inviter == role
      raise I18n.t('groups.invite_member.errors.inviting_self')
    elsif !extension.nil?
      raise I18n.t('groups.invite_member.errors.extension_exists')
    elsif self.student_membership_number >= self.assignment.group_max
      raise I18n.t('groups.invite_member.errors.group_max_reached', user_name: role.user_name)
    elsif self.assignment.section_groups_only && role.section != self.section
      raise I18n.t('groups.invite_member.errors.not_same_section', user_name: role.user_name)
    elsif role.has_accepted_grouping_for?(self.assignment.id)
      raise I18n.t('groups.invite_member.errors.already_grouped', user_name: role.user_name)
    elsif self.pending?(role)
      raise I18n.t('groups.invite_member.errors.already_pending', user_name: role.user_name)
    end
    true
  end

  # Returns the status of this user, or nil if user is not a member
  def membership_status(role)
    member = student_memberships.where(role_id: role.id).first
    member&.membership_status
  end

  # returns the numbers of memberships, all includ (inviter, pending,
  # accepted
  def student_membership_number
    accepted_students.size + pending_students.size
  end

  # Returns true if either this Grouping has met the assignment group
  # size minimum, OR has been approved by an instructor
  def is_valid?
    instructor_approved || (non_rejected_student_memberships.size >= assignment.group_min)
  end

  # Validates a group
  def validate_grouping
    self.instructor_approved = true
    self.save
  end

  # Strips instructor_approved privledge
  def invalidate_grouping
    self.instructor_approved = false
    self.save
  end

  def update_repo_permissions_after_save
    return unless assignment.read_attribute(:vcs_submit)
    return unless saved_change_to_attribute? :instructor_approved
    Repository.get_class.update_permissions
  end

  # Grace Credit Query
  def available_grace_credits
    total = []
    accepted_students.includes(:grace_period_deductions).find_each do |student|
      total.push(student.remaining_grace_credits)
    end
    total.min
  end

  # The grace credits deducted (of one student) for this specific submission
  # in the grouping
  def grace_period_deduction_single
    single = 0
    # Since for an instance of a grouping all members of the group will get
    # deducted the same amount (for a specific assignment), it is safe to pick
    # any deduction
    if !grace_period_deductions.nil? && !grace_period_deductions.first.nil?
      single = grace_period_deductions.first.deduction
    end
    single
  end

  # remove all deductions for this assignment for a particular member
  def remove_grace_period_deduction(membership)
    deductions = membership.role.grace_period_deductions
    deductions.each do |deduction|
      if deduction.membership.grouping.assignment.id == assignment.id
        membership.grace_period_deductions.delete(deduction)
        deduction.destroy
      end
    end
  end

  # Submission Functions
  def has_submission?
    # Return true if and only if this grouping has at least one submission
    # with attribute submission_version_used == true.
    !current_submission_used.nil?
  end

  def has_non_empty_submission?
    has_submission? && !current_submission_used.is_empty
  end

  # EDIT METHODS
  # Removes the member by its membership id
  def remove_member(mbr_id)
    member = student_memberships.find(mbr_id)
    if member
      # Remove repository permissions first
      member.destroy
      if member.membership_status == StudentMembership::STATUSES[:inviter] &&
          (member.grouping.accepted_student_memberships.length > 0)
        membership = member.grouping.accepted_student_memberships.first
        membership.membership_status = StudentMembership::STATUSES[:inviter]
        membership.save
      end
    end
  end

  def delete_grouping
    Repository.get_class.update_permissions_after(only_on_request: true) do
      student_memberships.includes(:role).find_each(&:destroy)
    end
    self.destroy
  end

  # Removes the member rejected by its membership id
  # Used as safeguard when student deletes the record
  def remove_rejected(mbr_id)
    member = memberships.find(mbr_id)
    member.destroy if member && member.membership_status == StudentMembership::STATUSES[:rejected]
  end

  def decline_invitation(student)
    membership = self.pending_student_memberships.find_by(role_id: student.id)
    raise I18n.t('groups.members.errors.not_found') if membership.nil?
    membership.update!(membership_status: StudentMembership::STATUSES[:rejected])
  end

  # If a group is invalid OR valid and the user is the inviter of the group and
  # she is the _only_ member of this grouping it should be deletable
  # by this user.
  # Additionally, the grace period for the assignment should not have passed.
  def deletable_by?(user)
    return false unless self.inviter == user
    !self.is_valid? || (self.is_valid? &&
                          accepted_students.size == 1 &&
                          self.assignment.group_assignment? &&
                          !assignment.past_collection_date?(self.section))
  end

  def select_starter_file_entries
    case assignment.starter_file_type
    when 'simple'
      assignment.default_starter_file_group&.starter_file_entries || []
    when 'sections'
      section = inviter&.section&.starter_file_group_for(assignment) || assignment.default_starter_file_group
      section&.starter_file_entries || []
    when 'shuffle'
      assignment.starter_file_groups.includes(:starter_file_entries).filter_map do |g|
        # If this grouping has previous starter files, try to choose an entry with the same path as before
        old_entry = g.starter_file_entries.find_by(path: self.starter_file_entries.map(&:path))
        old_entry || StarterFileEntry.find_by(id: g.starter_file_entries.ids.sample)
      end
    when 'group'
      # If this grouping has previous starter files, try to choose a group already assigned to the student
      group_ids = self.starter_file_entries.pluck(:starter_file_group_id).compact.sample
      group_ids ||= assignment.starter_file_groups.ids.sample
      StarterFileGroup.find_by(id: group_ids)&.starter_file_entries || []
    else
      raise "starter_file_type is invalid: #{assignment.starter_file_type}"
    end
  end

  def reset_starter_file_entries
    old_grouping_entry_ids = self.grouping_starter_file_entries.ids
    new_grouping_entry_ids = select_starter_file_entries.map do |entry|
      GroupingStarterFileEntry.find_or_create_by!(starter_file_entry_id: entry.id, grouping_id: self.id).id
    end
    self.grouping_starter_file_entries.where(id: old_grouping_entry_ids - new_grouping_entry_ids).destroy_all
    self.update!(starter_file_changed: false)
  end

  # Returns a list of missing assignment (required) files.
  # A repo revision can be passed directly if the caller already opened the repo.
  def missing_assignment_files(revision = nil)
    get_missing_assignment_files = ->(open_revision) do
      assignment.assignment_files.reject do |assignment_file|
        open_revision.path_exists?(File.join(assignment.repository_folder, assignment_file.filename))
      end
    end
    if revision.nil?
      access_repo do |repo|
        revision = repo.get_latest_revision
        get_missing_assignment_files.call revision
      end
    else
      get_missing_assignment_files.call revision
    end
  end

  # Return the due date for this grouping. If this grouping has an extension, the time_delta
  # of the extension is added to the due date.
  #
  # If the assignment is a timed assignment and the student has started working, the due date
  # is this grouping's start time plus the duration plus any extension.
  def due_date
    if assignment.section_due_dates_type
      a_due_date = assignment.assessment_section_properties
                             .find_by(section_id: inviter&.section)&.due_date || assignment.due_date
    else
      a_due_date = assignment.due_date
    end
    extension_time = extension&.time_delta || 0
    return a_due_date + extension_time if !assignment.is_timed || start_time.nil?

    start_time + extension_time + assignment.duration
  end

  # Returns whether the last submission for this grouping is after the grouping's collection date.
  # Takes into account assignment late penalties, sections, and extensions.
  def submitted_after_collection_date?
    grouping_due_date = collection_date
    revision = nil
    access_repo do |repo|
      # get the last revision that changed the assignment repo folder after the due date; some repos may not be able to
      # optimize by due_date (returning nil), so a check with revision.server_timestamp is always necessary
      revision = repo.get_revision_by_timestamp(Time.current, assignment.repository_folder, grouping_due_date)
    end
    !(revision.nil? || revision.server_timestamp <= grouping_due_date)
  end

  def collection_date
    assignment.submission_rule.calculate_grouping_collection_time(self)
  end

  def past_collection_date?
    collection_date < Time.current
  end

  def past_assessment_start_time?
    assignment.section_start_time(inviter&.section) < Time.current
  end

  # Return the duration of this grouping's assignment plus any extensions
  def duration
    assignment.duration + (extension&.time_delta || 0)
  end

  def self.get_assign_scans_grouping(assignment, grouping_id = nil)
    subquery = StudentMembership.all.to_sql
    assignment.groupings.includes(:non_rejected_student_memberships)
              .where(instructor_approved: false)
              .where('groupings.id > ?', grouping_id || 0)
              .joins(:current_submission_used)
              .joins("LEFT JOIN (#{subquery}) sub ON groupings.id = sub.grouping_id")
              .where(sub: { id: nil })
              .order(:id)
              .first
  end

  def review_for(reviewee_group)
    reviewee_group.peer_reviews.find_by(reviewer_id: id)
  end

  def refresh_test_tokens
    assignment = self.assignment
    if assignment.unlimited_tokens || Time.current < assignment.token_start_date
      self.test_tokens = 0
    else
      last_student_run = test_runs.where(role: accepted_students).first
      if last_student_run.nil?
        self.test_tokens = assignment.tokens_per_period
      else
        # divide time into chunks of token_period hours
        # recharge tokens only the first time they are used during the current chunk
        hours_from_start = (Time.current - assignment.token_start_date) / 3600
        if assignment.non_regenerating_tokens
          last_period_begin = assignment.token_start_date
        else
          periods_from_start = (hours_from_start / assignment.token_period).floor
          last_period_begin = assignment.token_start_date + (periods_from_start * assignment.token_period).hours
        end
        if last_student_run.created_at < last_period_begin
          self.test_tokens = assignment.tokens_per_period
        end
      end
    end
    save
  end

  def decrease_test_tokens
    if !self.assignment.unlimited_tokens && self.test_tokens > 0
      self.test_tokens -= 1
      save
    end
  end

  # TODO: Refactor into more flexible code from here to the end:
  # - be able to return test_runs currently in progress and add them to the react table
  def self.pluck_test_runs(assoc, filter_output: false, include_extra_info: true)
    # Active record tries to convert the test_results.status values based on the test_run.status
    # enum conversion. In order to prevent this, we have to rename test_results.status so that it
    # doesn't trigger this conversion.
    fields = ['test_runs.id', 'test_runs.created_at', 'test_runs.problems', 'test_runs.status',
              'roles.type', 'users.user_name',
              'test_groups.id', 'test_groups.name', 'test_groups.position', 'test_groups.display_output',
              'test_group_results.time',
              'test_results.name', 'test_results.status as test_results_status', 'test_results.marks_earned',
              'test_results.marks_total', 'test_results.output', 'test_results.time', 'test_results.position']
    fields << 'test_group_results.extra_info' if include_extra_info

    hash_list = assoc.pluck_to_hash(*fields)

    # Add feedback files. This has to be done separately because there can be multiple feedback files
    # per test_group_result.
    feedback_files = FeedbackFile.joins(test_group_result: [:test_run, :test_group])
                                 .where('test_runs.id': hash_list.pluck('test_runs.id'))
                                 .pluck_to_hash(:id, :filename, 'test_runs.id', 'test_groups.name')
                                 .group_by { |f| [f['test_runs.id'], f['test_groups.name']] }

    allowed_roles = %w[Instructor Ta AdminRole]
    allowed_output_settings = %w[instructors_and_student_tests instructors]

    hash_list.each do |h|
      h['feedback_files'] = feedback_files[[h['test_runs.id'], h['test_groups.name']]] || []
      h['feedback_files'].each do |f|
        f['type'] = FileHelper.get_file_type(f['filename'])
      end

      h['test_runs.created_at'] = I18n.l(h['test_runs.created_at'])

      # Hide display_output
      if filter_output && ((h['roles.type'] == 'Student' && h['test_groups.display_output'] == 'instructors') ||
            (allowed_roles.include?(h['roles.type']) &&
              allowed_output_settings.include?(h['test_groups.display_output'])))
        h.delete('test_results.output')
      end
    end

    hash_list
  end

  def test_runs_instructors(submission)
    filtered = test_runs_all_data.where('roles.type': %w[Instructor Ta AdminRole], 'test_runs.submission': submission)
    plucked = Grouping.pluck_test_runs(filtered)
    Util.group_hashes(plucked,
                      %w[test_runs.id test_runs.created_at test_runs.status test_runs.problems users.user_name],
                      :test_results)
  end

  def test_runs_instructors_released(submission)
    filtered = test_runs_all_data.where('roles.type': %w[Instructor Ta AdminRole], 'test_runs.submission': submission)
    latest_test_group_results = filtered.pluck_to_hash('test_groups.id',
                                                       'test_group_results.id',
                                                       'test_group_results.created_at')
                                        .group_by { |h| h['test_groups.id'] }
                                        .values
                                        .filter_map do |v|
      v.max_by do |h|
        h['test_group_results.created_at']
      end['test_group_results.id']
    end
    plucked = Grouping.pluck_test_runs(
      filtered.where('test_group_results.id': latest_test_group_results),
      filter_output: true,
      include_extra_info: false
    )
    Util.group_hashes(plucked,
                      %w[test_runs.id test_runs.created_at test_runs.status test_runs.problems users.user_name],
                      :test_results)
  end

  def test_runs_students
    filtered = test_runs_all_data.where('test_runs.role': self.accepted_students)
    plucked = Grouping.pluck_test_runs(filtered, filter_output: true, include_extra_info: false)
    Util.group_hashes(plucked,
                      %w[test_runs.id test_runs.created_at test_runs.status test_runs.problems users.user_name],
                      :test_results)
  end

  # Checks whether a student test using tokens is currently being enqueued for execution
  # (with buffer time in case of unhandled errors that prevented test results to be stored)
  def student_test_run_in_progress?
    buffer_time = Settings.autotest.student_test_buffer_minutes.minutes
    last_student_run = test_runs.where(role: self.accepted_students).first
    if last_student_run.nil? || # first test
      (last_student_run.created_at + buffer_time) < Time.current || # buffer time expired (for unhandled problems)
      !last_student_run.in_progress? # test results not back yet
      false
    else
      true
    end
  end

  def access_repo
    group.access_repo do |repo|
      add_assignment_folder(repo)
      yield repo if block_given?
    end
  end

  def get_next_grouping(current_role, reversed, filter_data = nil)
    if current_role.ta?
      results = self.assignment.current_results.joins(grouping: :tas).where(
        'roles.id': current_role.id
      )

    else
      results = self.assignment.current_results
    end
    results = results.joins(grouping: :group)
    if filter_data.nil?
      filter_data = {}
    end
    results = filter_results(current_role, results, filter_data)
    order_and_get_next_grouping(results, filter_data, reversed)
  end

  def get_random_incomplete(current_role)
    if current_role.ta? && self.assignment.assign_graders_to_criteria
      assigned_criteria = self.assignment.criteria.joins(:criterion_ta_associations)
                              .where(criterion_ta_associations: { ta_id: current_role.id })

      results = self.assignment.current_results.joins(:marks, grouping: :ta_memberships)
                    .where('memberships.role_id': current_role.id, 'marks.criterion_id': assigned_criteria.ids)
                    .where('marks.mark': nil)
    elsif current_role.ta?
      results = self.assignment.current_results.joins(grouping: :tas).where(
        marking_state: Result::MARKING_STATES[:incomplete],
        'roles.id': current_role.id
      )
    else
      results = self.assignment.current_results.where(
        marking_state: Result::MARKING_STATES[:incomplete]
      )
    end
    results.where.not('groupings.id': self.id).order('RANDOM()').first&.grouping
  end

  # Checks if a grouping uploaded any files
  def has_submitted_files?
    access_repo do |repo|
      revision = repo.get_revision_by_timestamp(Time.current)

      files = revision.tree_at_path(assignment.repository_folder, with_attrs: false).select do |_, obj|
        obj.is_a?(Repository::RevisionFile) && Repository.get_class.internal_file_names.exclude?(obj.name)
      end

      return files.length > 0
    end
  end

  private

  # Takes in a collection of results specified by +results+, and filters them using +filter_data+. Assumes
  # +filter_data+ is not nil.
  # +filter_data['annotationText']+ is a string specifying some annotation text to filter by.
  # +filter_data['section']+ is a string specifying the name of the section to filter by.
  # +filter_data['markingState']+ is a string specifying the marking state to filter by; valid strings
  # include "remark_requested", "released", "complete", "in_progress" and "".
  # +filter_data['tas']+ is a list of strings corresponding to ta user names specifying the tas to filter by.
  # +filter_data['tags']+ is a list of strings corresponding to tag names specifying the tags to filter by.
  # +filter_data['totalMarkRange']+ is a hash with the keys 'min' and 'max' each mapping to a string representing a
  # float. 'max' is the maximum and 'min' is the minimum total mark a result should have.
  # +filter_data['totalExtraMarkRange']+ is a hash with the keys 'min' and 'max' each mapping to a string representing
  # a float. 'max' is the maximum and 'min' is the minimum total extra mark a result should have.
  # +filter_data['criteria']+ is hash containing information about criteria to filter by. Each key should be a string
  # corresponding to the criterion name and should map to a hash with keys 'min' and/or 'max' each mapping to a string
  # representing a float. 'max' is the maximum and 'min' is the minimum grade for the given criterion a result should
  # have. If both 'max' and 'min' are blank (a whitespace string/nil), filtering for the corresponding criterion will
  # not occur. To avoid filtering by any of the specified filters, don't set values for the corresponding key in
  # +filter_data+ or set it to nil. If the value for a key is blank (false, empty, or a whitespace string, as
  # determined by `.blank?`), no filtering will occur for the corresponding option.
  def filter_results(current_role, results, filter_data)
    if filter_data['annotationText'].present?
      results = results.joins(annotations: :annotation_text)
                       .where('lower(annotation_texts.content) LIKE ?',
                              "%#{AnnotationText.sanitize_sql_like(filter_data['annotationText'].downcase)}%")
    end
    if filter_data['section'].present?
      results = results.joins(grouping: :section).where('section.name': filter_data['section'])
    end
    if filter_data['markingState'].present?
      remark_results = results.where.not('results.remark_request_submitted_at': nil)
                              .where('results.marking_state': Result::MARKING_STATES[:incomplete])
      released_results = results.where.not('results.id': remark_results).where('results.released_to_students': true)
      case filter_data['markingState']
      when 'remark_requested'
        results = remark_results
      when 'released'
        results = released_results
      when 'complete'
        results = results.where.not('results.id': released_results)
                         .where('results.marking_state': Result::MARKING_STATES[:complete])
      when 'in_progress'
        results = results.where.not('results.id': remark_results).where.not('results.id': released_results)
                         .where('results.marking_state': Result::MARKING_STATES[:incomplete])
      end
    end

    unless current_role.ta? || filter_data['tas'].blank?
      results = results.joins(grouping: { tas: :user }).where('user.user_name': filter_data['tas'])
    end
    if filter_data['tags'].present?
      results = results.joins(grouping: :tags).where('tags.name': filter_data['tags'])
    end
    unless filter_data.dig('totalMarkRange', 'max').blank? && filter_data.dig('totalMarkRange', 'min').blank?
      result_ids = results.ids
      total_marks_hash = Result.get_total_marks(result_ids)
      if filter_data.dig('totalMarkRange', 'max').present?
        total_marks_hash.select! { |_, value| value <= filter_data['totalMarkRange']['max'].to_f }
      end
      if filter_data.dig('totalMarkRange', 'min').present?
        total_marks_hash.select! { |_, value| value >= filter_data['totalMarkRange']['min'].to_f }
      end
      results = Result.where('results.id': total_marks_hash.keys)
    end
    unless filter_data.dig('totalExtraMarkRange', 'max').blank? && filter_data.dig('totalExtraMarkRange', 'min').blank?
      result_ids = results.ids
      total_marks_hash = Result.get_total_extra_marks(result_ids)
      if filter_data.dig('totalExtraMarkRange', 'max').present?
        total_marks_hash.select! do |_, value|
          value <= filter_data['totalExtraMarkRange']['max'].to_f
        end
      end
      if filter_data.dig('totalExtraMarkRange', 'min').present?
        total_marks_hash.select! do |_, value|
          value >= filter_data['totalExtraMarkRange']['min'].to_f
        end
      end
      results = Result.where('results.id': total_marks_hash.keys)
    end
    if filter_data['criteria'].present?
      results = results.joins(marks: :criterion)
      temp_results = Result.none
      num_criteria = 0
      filter_data['criteria'].each do |name, range|
        num_criteria += 1
        if range.present? && range['min'].present? && range['max'].present?
          temp_results = temp_results.or(results
                                           .where('criteria.name = ? AND marks.mark >= ? AND marks.mark <= ?',
                                                  name, range['min'].to_f, range['max'].to_f))
        elsif range.present? && range['min'].present?
          temp_results = temp_results.or(results
                                           .where('criteria.name = ? AND marks.mark >= ?',
                                                  name, range['min'].to_f))
        elsif range.present? && range['max'].present?
          temp_results = temp_results.or(results
                                           .where('criteria.name = ? AND marks.mark <= ?',
                                                  name, range['max'].to_f))
        else
          temp_results = temp_results.or(results
                                           .where(criteria: { name: name }))
        end
      end
      results = temp_results.group(:id).having('count(results.id) >= ?', num_criteria)
    end
    results.joins(grouping: :group)
  end

  # Orders the results, specified as +results+ by using +filter_data+ and returns the next grouping using +reversed+.
  # +reversed+ is a boolean value, true to return the next grouping and false to return the previous one.
  # +filter_data['orderBy']+ specifies how the results should be ordered, with valid values being "group_name",
  # "submission_date" and "total_mark". When this value is not specified (or nil), default ordering is applied.
  # +filter_data['ascending']+ specifies whether results should be ordered in ascending or descending order. Valid
  # options include "true" (corresponding to ascending order) or "false" (corresponding to descending order). When
  # this value is not specified (or nil), the results are ordered in ascending order.
  def order_and_get_next_grouping(results, filter_data, reversed)
    asc_temp = filter_data['ascending'].nil? || filter_data['ascending'] == 'true' ? 'ASC' : 'DESC'
    ascending = (asc_temp == 'ASC' && !reversed) || (asc_temp == 'DESC' && reversed) || false
    case filter_data['orderBy']
    when 'submission_date'
      next_grouping_ordered_submission_date(results, ascending)
    when 'total_mark'
      next_grouping_ordered_total_mark(results, ascending)
    else # group name/otherwise
      next_grouping_ordered_group_name(results, ascending)
    end
  end

  # Gets the next grouping by first ordering +results+ by group name in either ascending
  # (+ascending+ = true) or descending (+ascending+ = false) order and then extracting the next grouping.
  # If there is no next grouping, nil is returned.
  def next_grouping_ordered_group_name(results, ascending)
    results = results.group([:id, 'groups.group_name']).order('groups.group_name ASC')
    if ascending
      next_result = results.where('groups.group_name > ?', self.group.group_name).first
    else
      # rubocop:disable Rails/WhereRange
      next_result = results.where('groups.group_name < ?', self.group.group_name).last
      # rubocop:enable Rails/WhereRange
    end
    next_result&.grouping
  end

  # Gets the next grouping by first ordering +results+ by submission date and then by group name in either ascending
  # (+ascending+ = true) or descending (+ascending+ = false) order and then extracting the next grouping.
  # If there is no next grouping, nil is returned.
  def next_grouping_ordered_submission_date(results, ascending)
    results = results.joins(:submission).group([:id, 'groups.group_name', 'submissions.revision_timestamp'])
                     .order('submissions.revision_timestamp ASC',
                            'groups.group_name ASC')
    if ascending
      next_result = results
                    .where('submissions.revision_timestamp > ?', self.current_submission_used.revision_timestamp)
                    .or(results.where('groups.group_name > ? AND submissions.revision_timestamp = ?',
                                      self.group.group_name,
                                      self.current_submission_used.revision_timestamp)).first

    else
      # rubocop:disable Rails/WhereRange
      next_result = results
                    .where('submissions.revision_timestamp < ?', self.current_submission_used.revision_timestamp)
                    .or(results.where('groups.group_name < ? AND submissions.revision_timestamp = ?',
                                      self.group.group_name,
                                      self.current_submission_used.revision_timestamp)).last
      # rubocop:enable Rails/WhereRange
    end
    next_result&.grouping
  end

  # Gets the next grouping by first ordering +results+ by total mark in either ascending
  # (+ascending+ = true) or descending (+ascending+ = false) order and then extracting the next grouping.
  # If there is no next grouping, nil is returned.
  def next_grouping_ordered_total_mark(results, ascending)
    # if the current result isn't present in results, add it for future processing
    results = results.or(Result.where('results.id': self.current_result.id))
    result_data = results.pluck('results.id', 'groups.group_name').uniq { |id, _| id }
    total_marks = Result.get_total_marks(result_data.map { |id, _| id })
    result_data.each do |el|
      el.append(total_marks[el[0]])
    end
    result_data = result_data.sort_by { |_, group_name, total_mark| [total_mark, group_name] }
    curr_res_index = result_data.bsearch_index do |_, group_name, total_mark|
      [total_marks[self.current_result.id], self.group.group_name] <=> [total_mark, group_name]
    end
    if ascending
      next_res_index = curr_res_index + 1
    else
      next_res_index = curr_res_index - 1
    end
    if next_res_index >= 0 && next_res_index < result_data.length
      return Result.find(result_data[next_res_index][0]).grouping
    end
    nil
  end

  def add_assignment_folder(group_repo)
    assignment_folder = self.assignment.repository_folder

    # path may already exist if this is a peer review assignment. In that case do not create
    # starter files since it should already be there from the parent assignment.
    unless group_repo.get_latest_revision.path_exists?(assignment_folder)
      txn = group_repo.get_transaction('Markus', I18n.t('repo.commits.assignment_folder',
                                                        assignment: self.assignment.short_identifier))
      txn.add_path(assignment_folder)

      if txn.has_jobs? && !group_repo.commit(txn)
        raise I18n.t('repo.assignment_dir_creation_error', short_identifier: assignment.short_identifier)
      end
    end
  end

  def use_section_due_date?
    assignment.section_due_dates_type &&
      inviter.present? &&
      inviter.section.present? &&
      assignment.section_due_dates.present?
  end

  def assignments_should_match
    return if assessment_id.nil?
    unless self.tags.pluck(:assessment_id).compact.all?(self.assessment_id)
      errors.add(:base, 'tags must belong to the same assignment as this grouping')
    end
  end
end
