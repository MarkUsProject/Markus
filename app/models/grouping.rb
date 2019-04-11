require 'set'

# Represents a collection of students working together on an assignment in a group
class Grouping < ApplicationRecord
  include ActiveRecordCreator
  include SubmissionsHelper

  after_create_commit :create_grouping_repository_folder
  after_commit :update_repo_permissions_after_save, on: [:create, :update]

  belongs_to :grouping_queue, optional: true

  has_many :memberships, dependent: :destroy
  has_many :student_memberships, -> { order('id') }
  has_many :non_rejected_student_memberships,
           -> { where ['memberships.membership_status != ?', StudentMembership::STATUSES[:rejected]] },
           class_name: 'StudentMembership'

  has_many :accepted_student_memberships,
           -> { where 'memberships.membership_status' => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]] },
           class_name: 'StudentMembership'

  has_many :notes, as: :noteable, dependent: :destroy
  has_many :ta_memberships, class_name: 'TaMembership'
  has_many :tas, through: :ta_memberships, source: :user
  has_many :students, through: :student_memberships, source: :user
  has_many :pending_students,
           -> { where 'memberships.membership_status' => StudentMembership::STATUSES[:pending] },
           class_name: 'Student',
           through: :student_memberships,
           source: :user
  has_many :accepted_students,
           class_name: 'Student',
           through: :accepted_student_memberships,
           source: :user
  has_many :submissions
  has_one :current_submission_used,
          -> { where submission_version_used: true },
          class_name: 'Submission'
  has_one :current_result, through: :current_submission_used

  has_and_belongs_to_many :tags

  has_many :grace_period_deductions,
           through: :non_rejected_student_memberships

  has_many :test_runs, -> { order 'created_at DESC' }, dependent: :destroy
  has_many :test_runs_all_data,
           -> { left_outer_joins(:user, test_group_results: [:test_group, :test_results]).order('created_at DESC') },
           class_name: 'TestRun'

  has_one :inviter_membership,
          -> { where membership_status: StudentMembership::STATUSES[:inviter] },
          class_name: 'StudentMembership'

  has_one :inviter, source: :user, through: :inviter_membership, class_name: 'Student'

  # The following are chained
  # 'peer_reviews' is the peer reviews given for this group via some result
  # 'peer_reviews_to_others' is all the peer reviews this grouping gave to others
  has_many :results, through: :current_submission_used
  has_many :peer_reviews, through: :results
  has_many :peer_reviews_to_others, class_name: 'PeerReview', foreign_key: 'reviewer_id'

  scope :approved_groupings, -> { where admin_approved: true }

  validates_numericality_of :criteria_coverage_count, greater_than_or_equal_to: 0

  # user association/validation
  belongs_to :assignment, counter_cache: true
  validates_associated :assignment, on: :create

  belongs_to :group
  validates_associated :group

  validates_inclusion_of :is_collected, in: [true, false]

  validates_presence_of :test_tokens
  validates_numericality_of :test_tokens, greater_than_or_equal_to: 0, only_integer: true

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each
  # grouping in a list of groupings specified by +grouping_ids+. The groupings
  # must belong to the given assignment +assignment+.
  def self.randomly_assign_tas(grouping_ids, ta_ids, assignment)
    assign_tas(grouping_ids, ta_ids, assignment) do |grouping_ids, ta_ids|
      # Assign TAs in a round-robin fashion to a list of random groupings.
      grouping_ids.shuffle.zip(ta_ids.cycle)
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each grouping in
  # a list of groupings specified by +grouping_ids+. The groupings must belong
  # to the given assignment +assignment+.
  def self.assign_all_tas(grouping_ids, ta_ids, assignment)
    assign_tas(grouping_ids, ta_ids, assignment) do |grouping_ids, ta_ids|
      # Get the Cartesian product of grouping IDs and TA IDs.
      grouping_ids.product(ta_ids)
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
    ta_ids = Ta.where(id: ta_ids).pluck(:id)
    grouping_ids = Grouping.where(id: grouping_ids).pluck(:id)
    columns = [:grouping_id, :user_id, :type]
    # Get all existing memberships to avoid violating the unique constraint.
    existing_values = TaMembership
                      .where(grouping_id: grouping_ids, user_id: ta_ids)
                      .pluck(:grouping_id, :user_id)
    # Delegate the assign function to the caller-specified block and remove
    # values that already exist in the database.
    values = yield(grouping_ids, ta_ids) - existing_values
    # TODO replace TaMembership.import with TaMembership.create when the PG
    # driver supports bulk create, then remove the activerecord-import gem.
    values.map! do |value|
      value.push('TaMembership')
    end
    Repository.get_class.update_permissions_after do
      Membership.import(columns, values, validate: false)
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
      grouping_ids = assignment.groupings.pluck(:id)
    end
    counts = CriterionTaAssociation
             .from(
               # subquery
               assignment.criterion_ta_associations
                         .joins(ta: :groupings)
                         .where('groupings.id': grouping_ids)
                         .select('criterion_ta_associations.criterion_id',
                                 'criterion_ta_associations.criterion_type',
                                 'groupings.id')
                         .distinct
             )
             .group('subquery.id')
             .count

    Upsert.batch(Grouping.connection, Grouping.table_name) do |upsert|
      grouping_ids.each do |gid|
        upsert.row({ id: gid }, criteria_coverage_count: counts[gid.to_i] || 0)
      end
    end
  end

  def get_all_students_in_group
    student_user_names = student_memberships.includes(:user).collect {|m| m.user.user_name }
    return I18n.t('groups.empty') if student_user_names.empty?
	  student_user_names.join(', ')
  end

  def does_not_share_any_students?(grouping)
    current_student_ids = Set.new
    other_group_student_ids = Set.new
    students.each { |student| current_student_ids.add(student.id) }
    grouping.students.each { |student| other_group_student_ids.add(student.id) }
    not current_student_ids.intersect?(other_group_student_ids)
  end

  def get_group_name
    return group.group_name if assignment.group_max == 1 && !assignment.scanned_exam

    name = group.group_name
    student_names = accepted_students.map &:user_name
    unless student_names == [name]
      name += ' (' + student_names.join(', ') + ')'
    end
    name
  end

  def group_name_with_student_user_names
    user_names = get_all_students_in_group
    return group.group_name if user_names == I18n.t('groups.empty')
    group.group_name + ': ' + user_names
  end

  def display_for_note
    assignment.short_identifier + ': ' + group_name_with_student_user_names
  end

  # Query Functions ------------------------------------------------------

  # Returns whether or not a TA is assigned to mark this Grouping
  def has_ta_for_marking?
    ta_memberships.count > 0
  end

  #Returns whether or not the submission_collector is pending to collect this
  #grouping's newest submission
  def is_collected?
    is_collected
  end

  # Returns an array of the user_names for any TA's assigned to mark
  # this Grouping
  def get_ta_names
    ta_memberships.collect do |membership|
      membership.user.user_name
    end
  end

  # Returns true if this user has a pending status for this group;
  # false otherwise, or if user is not in this group.
  def pending?(user)
    membership_status(user) == StudentMembership::STATUSES[:pending]
  end

  # returns whether the user is the inviter of this group or not.
  def is_inviter?(user)
    membership_status(user) ==  StudentMembership::STATUSES[:inviter]
  end

  # invites each user in 'members' by its user name, to this group
  # If the method is invoked by an admin, checks on whether the students can
  # be part of the group are skipped.
  def invite(members,
             set_membership_status=StudentMembership::STATUSES[:pending],
             invoked_by_admin=false)
    # overloading invite() to accept members arg as both a string and a array
    members = [members] if !members.instance_of?(Array) # put a string in an
                                                 # array
    members.each do |m|
      next if m.blank? # ignore blank users
      m = m.strip
      user = User.where(user_name: m).first
      m_logger = MarkusLogger.instance
      if user
        if invoked_by_admin || self.can_invite?(user)
          member = self.add_member(user, set_membership_status)
          if member
            m_logger.log("Student invited '#{user.user_name}'.")
          else
            errors.add(:base, I18n.t('invite_student.fail.error',
                                     user_name: user.user_name))
            m_logger.log("Student failed to invite '#{user.user_name}'",
                         MarkusLogger::ERROR)
          end
        end
      else
        errors.add(:base, I18n.t('invite_student.fail.dne',
                                 user_name: m))
      end
    end
  end

  # Add a new member to base
  def add_member(user, set_membership_status = StudentMembership::STATUSES[:accepted])
    if user.has_accepted_grouping_for?(self.assignment_id) || user.hidden
      nil
    else
      member = StudentMembership.new(user: user, membership_status:
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
  def can_invite?(user)
    m_logger = MarkusLogger.instance
    if user && user.student?
      if user.hidden
        errors.add(:base, I18n.t('invite_student.fail.hidden',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}' (account has been " +
                     'disabled).', MarkusLogger::ERROR)

        return false
      end
      if self.inviter == user
        errors.add(:base, I18n.t('invite_student.fail.inviting_self',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}'. Tried to invite " +
                     'himself.', MarkusLogger::ERROR)


      end
      if self.assignment.past_collection_date?(self.inviter.section)
        errors.add(:base, I18n.t('invite_student.fail.due_date_passed',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}'. Current time past " +
                     'collection date.', MarkusLogger::ERROR)

        return false
      end
      if self.student_membership_number >= self.assignment.group_max
        errors.add(:base, I18n.t('invite_student.fail.group_max_reached',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}'. Group maximum" +
                     ' reached.', MarkusLogger::ERROR)
        return false
      end
      if self.assignment.section_groups_only &&
        user.section != self.inviter.section
        errors.add(:base, I18n.t('invite_student.fail.not_same_section',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}'. Students not in" +
                     ' same section.', MarkusLogger::ERROR)

        return false
      end
      if user.has_accepted_grouping_for?(self.assignment.id)
        errors.add(:base, I18n.t('invite_student.fail.already_grouped',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}'. Invitee already part" +
                     ' of another group.', MarkusLogger::ERROR)
        return false
      end
      if self.pending?(user)
        errors.add(:base, I18n.t('invite_student.fail.already_pending',
                                  user_name: user.user_name))
        m_logger.log("Student failed to invite '#{user.user_name}'. Invitee is already " +
                     ' pending member of this group.', MarkusLogger::ERROR)
        return false
      end
    else
      errors.add(:base, I18n.t('invite_student.fail.dne',
                                user_name: user.user_name))
      m_logger.log("Student failed to invite '#{user.user_name}'. Invitee does not " +
                   ' exist.', MarkusLogger::ERROR)
      return false
    end
    true
  end

  # Returns the status of this user, or nil if user is not a member
  def membership_status(user)
    member = student_memberships.where(user_id: user.id).first
    member ? member.membership_status : nil  # return nil if user is not a member
  end

  # returns the numbers of memberships, all includ (inviter, pending,
  # accepted
  def student_membership_number
     accepted_students.size + pending_students.size
  end

  # Returns true if either this Grouping has met the assignment group
  # size minimum, OR has been approved by an instructor
  def is_valid?
    admin_approved || (non_rejected_student_memberships.size >= assignment.group_min)
  end

  # Validates a group
  def validate_grouping
    self.admin_approved = true
    self.save
  end

  # Strips admin_approved privledge
  def invalidate_grouping
    self.admin_approved = false
    self.save
  end

  def update_repo_permissions_after_save
    return unless assignment.read_attribute(:vcs_submit)
    return unless saved_change_to_attribute? :admin_approved
    Repository.get_class.update_permissions
  end

  # Grace Credit Query
  def available_grace_credits
    total = []
    accepted_students.includes(:grace_period_deductions).each do |student|
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
    deductions = membership.user.grace_period_deductions
    deductions.each do |deduction|
      if deduction.membership.grouping.assignment.id == assignment.id
        membership.grace_period_deductions.delete(deduction)
        deduction.destroy
      end
    end
  end

  # Submission Functions
  def has_submission?
    #Return true if and only if this grouping has at least one submission
    #with attribute submission_version_used == true.
    !current_submission_used.nil?
  end

  def marking_completed?
    !current_result.nil? && current_result.marking_state == Result::MARKING_STATES[:complete]
  end

  # EDIT METHODS
  # Removes the member by its membership id
  def remove_member(mbr_id)
    member = student_memberships.find(mbr_id)
    if member
      # Remove repository permissions first
      member.destroy
      if member.membership_status == StudentMembership::STATUSES[:inviter]
         if member.grouping.accepted_student_memberships.length > 0
            membership = member.grouping.accepted_student_memberships.first
            membership.membership_status = StudentMembership::STATUSES[:inviter]
            membership.save
         end
      end
    end
  end

  def delete_grouping
    Repository.get_class.update_permissions_after(only_on_request: true) do
      student_memberships.includes(:user).each(&:destroy)
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
    membership = student.memberships.where(grouping_id: id).first
    membership.membership_status = StudentMembership::STATUSES[:rejected]
    membership.save
  end

  # If a group is invalid OR valid and the user is the inviter of the group and
  # she is the _only_ member of this grouping it should be deletable
  # by this user.
  # Additionally, the grace period for the assignment should not have passed.
  def deletable_by?(user)
    return false unless self.inviter == user
    (!self.is_valid?) || (self.is_valid? &&
                          accepted_students.size == 1 &&
                          self.assignment.group_assignment? &&
                          !assignment.past_collection_date?(self.inviter.section))
  end

  def add_tas(tas)
    Grouping.assign_all_tas(id, Array(tas).map(&:id), assignment)
  end

  def remove_tas(ta_id_array)
    #if no tas to remove, return.
    return if ta_id_array == []
    ta_memberships_to_remove = ta_memberships.includes(:user)
                                             .references(:user)
                                             .where(user_id: ta_id_array)
    ta_memberships_to_remove.each do |ta_membership|
      ta_membership.destroy
      ta_memberships.delete(ta_membership)
    end
    criteria = self.all_assigned_criteria(self.tas - ta_memberships_to_remove.collect{|mem| mem.user})
    self.criteria_coverage_count = criteria.length
    self.save
  end

  # When a Grouping is created, automatically create the folder for the
  # assignment in the repository, if it doesn't already exist.
  def create_grouping_repository_folder
    return unless MarkusConfigurator.markus_config_repository_admin? # create folder only if we are repo admin
    result = true
    self.group.access_repo do |group_repo|
      assignment_folder = self.assignment.repository_folder
      unless group_repo.get_latest_revision.path_exists?(assignment_folder)
        txn = group_repo.get_transaction('Markus', I18n.t('repo.commits.assignment_folder',
                                                          assignment: self.assignment.short_identifier))
        txn.add_path(assignment_folder)
        result = group_repo.commit(txn)
      end
      next unless Repository.get_class.repository_exists?(self.assignment.starter_code_repo_path)
      self.assignment.access_starter_code_repo do |starter_repo|
        starter_revision = starter_repo.get_latest_revision
        next unless starter_revision.path_exists?(assignment_folder)
        starter_tree = starter_revision.tree_at_path(assignment_folder, with_attrs: false)
        txn = self.assignment.update_starter_code_files(group_repo, starter_repo, starter_tree)
        if txn.has_jobs?
          result = group_repo.commit(txn)
          self.starter_code_revision_identifier = group_repo.get_latest_revision.revision_identifier
        end
      end
    end

    result
  end

  def assigned_tas_for_criterion(criterion)
    if assignment.assign_graders_to_criteria
      tas.select do |ta|
        ta.criterion_ta_associations
          .where(criterion_id: criterion.id)
          .first
      end
    else
      []
    end
  end

  def all_assigned_criteria(ta_array)
    result = []
    if assignment.assign_graders_to_criteria
      ta_array.each do |ta|
        result = result.concat(ta.get_criterion_associations_by_assignment(assignment))
      end
    end
    result.map{|a| a.criterion}.uniq
  end

  # Get the section for this group. If assignment restricts member of a groupe
  # to a section, all students are in the same section. Therefore, return only
  # the inviters section
  def section
    if !self.inviter.nil? and self.inviter.has_section?
      return self.inviter.section.name
    end
    '-'
  end

  # Returns a list of missing assignment (required) files.
  # A repo revision can be passed directly if the caller already opened the repo.
  def missing_assignment_files(revision = nil)
    repo = nil
    if revision.nil?
      repo = group.repo
      revision = repo.get_latest_revision
    end
    missing_assignment_files = assignment.assignment_files.reject do |assignment_file|
      revision.path_exists?(File.join(assignment.repository_folder, assignment_file.filename))
    end
    repo&.close
    missing_assignment_files
  end

  # Finds the correct due date (section or not) and checks if the last commit is after it.
  def past_due_date?
    if inviter.blank? || inviter.section.blank? || assignment.section_due_dates.blank?
      due_date = assignment.due_date
    else
      due_date = assignment.section_due_dates.find_by(section_id: inviter.section.id).due_date
    end
    revision = nil
    group.access_repo do |repo|
      # get the last revision that changed the assignment repo folder after the due date; some repos may not be able to
      # optimize by due_date (returning nil), so a check with revision.server_timestamp is always necessary
      revision = repo.get_revision_by_timestamp(Time.current, assignment.repository_folder, due_date)
    end
    if revision.nil? || revision.server_timestamp <= due_date
      false
    else
      true
    end
  end

  def self.get_groupings_for_assignment(assignment, user)
    if user.ta?
      assignment.ta_memberships.includes(grouping: [:group,
                                                    :assignment,
                                                    :tags,
                                                    :inviter,
                                                    :grace_period_deductions,
                                                    current_submission_used:
                                                      [:submission_files,
                                                       :submitted_remark,
                                                       :results,
                                                       grouping: :group],
                                                    accepted_student_memberships:
                                                      [:grace_period_deductions,
                                                       :user]])
                .where(user: user)
                .select { |m| assignment.scanned_exam? || m.grouping.is_valid? }
                .map &:grouping
    elsif user.is_a_reviewer?(assignment)
      # grab only the groupings of reviewees that this reviewer
      # is responsible for
      user_group = user.grouping_for(assignment.id)
      groupings = user_group.peer_reviews_to_others
      groupings.map {|p| Result.find(p.result_id).submission.grouping}
    elsif user.admin? && assignment.scanned_exam?
      assignment.groupings.includes(:group)
    else
      assignment.groupings.joins(:memberships)
          .includes(:assignment,
                    :group,
                    :grace_period_deductions,
                    :tags,
                    :peer_reviews_to_others,
                    { current_submission_used: [:results,
                                                :submission_files,
                                                :submitted_remark,
                                                grouping: :group] },
                    { accepted_student_memberships: :user },
                    { inviter: :section }
          )
          .where(memberships: { membership_status:
                                    [StudentMembership::STATUSES[:inviter],
                                     StudentMembership::STATUSES[:pending],
                                     StudentMembership::STATUSES[:accepted]] })
          .distinct
    end
  end

  def self.get_assign_scans_grouping(assignment, grouping_id = nil)
    subquery = StudentMembership.all.to_sql
    assignment.groupings.includes(:non_rejected_student_memberships)
              .where(admin_approved: false)
              .where('groupings.id > ?', grouping_id || 0)
              .joins(:current_submission_used)
              .joins("LEFT JOIN (#{subquery}) sub ON groupings.id = sub.grouping_id")
              .where(sub: { id: nil })
              .order(:id)
              .first
  end

  # Helper for populate_submissions_table.
  # Returns a formatted time string for the last commit time for this grouping.
  def last_commit_date
    if !current_submission_used&.revision_timestamp.nil?
      I18n.l(current_submission_used.revision_timestamp)
    else
      '-'
    end
  end

  # Helper for populate_submission_table
  # Returns boolean value based on if the submission has files or not
  def has_files_in_submission?
    !has_submission? ||
    !current_submission_used.submission_files.empty?
  end

  # Helper for populate_submissions_table.
  # Returns the final grade for this grouping.
  def final_grade(result)
    if !result.nil?
      result.total_mark
    else
      '-'
    end
  end

  # Helper for populate_submissions_table.
  # Returns the total bonus/deductions for this grouping including late penalty.
  def total_extra_points(result)
    if !result.nil?
      total_extra = result.get_total_extra_points + result.get_total_extra_percentage_as_points
      if result.get_total_extra_percentage_as_points == 0
        total_extra
      else
        "#{total_extra} (#{SubmissionRule.model_name.human.capitalize} : #{result.get_total_extra_percentage}%)"
      end
    else
      '-'
    end
  end

  # Helper for populate_submissions_table.
  # Returns the current marking state for the submission.
  # It would be nice to use Result::MARKING_STATES, but that doesn't have
  # states for released or remark requested.
  # result is the current result, if it exists
  def marking_state(result, assignment, user)
    if !user.student? && assignment.is_peer_review?
      # if an admin or TA is viewing peer review submissions
      pr_results = peer_reviews_to_others.map &:result
      if pr_results.empty?
        return 'partial'
      end
      unreleased_results = pr_results.find_all {|r| !r.released_to_students}
      if unreleased_results.size == 0
        'released'
      else
        'partial'
      end
    else
      if !has_submission?
        I18n.t('results.state.not_collected')
      elsif result.released_to_students
        'released'
      elsif result.marking_state != Result::MARKING_STATES[:complete]
        if current_submission_used.has_remark?
          'remark'
        else
          'partial'
        end
      else
        'completed'
      end
    end
  end

  def review_for(reviewee_group)
    reviewee_group.peer_reviews.find_by(reviewer_id: id)
  end

  def refresh_test_tokens
    assignment = self.assignment
    if assignment.unlimited_tokens || Time.current < assignment.token_start_date
      self.test_tokens = 0
    else
      last_student_run = test_runs_students_simple.first
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
  # - ability to chain filters instead of exploding all cases
  # - pluck_test_runs and group_hash_list could be done in a single loop probably
  # - be able to return test_runs currently in progress and add them to the react table
  def filter_test_runs(filters: {}, all_data: true)
    if all_data
      runs = self.test_runs_all_data
    else
      runs = self.test_runs
    end
    runs.where(filters)
  end

  def self.pluck_test_runs(assoc)
    fields = ['test_runs.id', 'test_runs.created_at', 'test_runs.problems', 'users.user_name', 'test_groups.name',
              'test_groups.display_output', 'test_group_results.extra_info', 'test_group_results.time',
              'test_results.name', 'test_results.status', 'test_results.marks_earned', 'test_results.marks_total',
              'test_results.output', 'test_results.time']
    assoc.pluck_to_hash(*fields)
  end

  def self.group_hash_list(hash_list)
    new_hash_list = []
    group_by_keys = ['test_runs.id', 'test_runs.created_at', 'test_runs.problems', 'users.user_name',
                     'test_groups.name']
    hash_list.group_by { |g| g.values_at(*group_by_keys) }.values.each do |val|
      h = Hash.new
      group_by_keys.each do |key|
        h[key] = val[0][key]
      end
      h['test_data'] = val
      new_hash_list << h
    end

    status_hash = TestRun.statuses(new_hash_list.map { |h| h['test_runs.id'] })
    new_hash_list.each do |h|
      h['test_runs.status'] = status_hash[h['test_runs.id']]
    end

    new_hash_list
  end

  def test_runs_instructors(submission)
    filtered = filter_test_runs(filters: { 'users.type': 'Admin', 'test_runs.submission': submission })
    plucked = Grouping.pluck_test_runs(filtered)
    Grouping.group_hash_list(plucked)
  end

  def test_runs_instructors_released(submission)
    filtered = filter_test_runs(filters: { 'users.type': 'Admin', 'test_runs.submission': submission })
    plucked = Grouping.pluck_test_runs(filtered)
    plucked.map! do |data|
      if data['test_groups.display_output'] == 'instructors_and_student_tests' ||
         data['test_groups.display_output'] == 'instructors'
        data.delete('test_results.output')
      end
      data.delete('test_group_results.extra_info')
      data
    end
    Grouping.group_hash_list(plucked)
  end

  def test_runs_students
    filtered = filter_test_runs(filters: { 'test_runs.user': self.accepted_students })
    plucked = Grouping.pluck_test_runs(filtered)
    plucked.map! do |data|
      if data['test_groups.display_output'] == 'instructors'
        data.delete('test_results.output')
      end
      data.delete('test_group_results.extra_info')
      data
    end
    Grouping.group_hash_list(plucked)
  end

  def test_runs_students_simple
    filter_test_runs(filters: { 'test_runs.user': self.accepted_students }, all_data: false)
  end

  # Create a test run for this grouping, using the latest repo revision.
  def create_test_run!(**attrs)
    self.test_runs.create!(
      user_id: get_id_for!(:user, attrs),
      revision_identifier: self.group.access_repo { |repo| repo.get_latest_revision.revision_identifier },
      test_batch_id: get_id_for(:test_batch, attrs)
    )
  end

  # Checks whether a student test using tokens is currently being enqueued for execution
  # (with buffer time in case of unhandled errors that prevented test results to be stored)
  def student_test_run_in_progress?
    buffer_time = MarkusConfigurator.autotest_student_tests_buffer_time
    last_student_run = test_runs_students_simple.first
    if last_student_run.nil? || # first test
      (last_student_run.created_at + buffer_time) < Time.current || # buffer time expired (for unhandled problems)
      !last_student_run.in_progress? # test results not back yet
      false
    else
      true
    end
  end

  # Add new files or overwrite existing files in this group's repo. +files+ should be a list
  # of ActionDispatch::Http::UploadedFile objects, +user+ is the user that is responsible for
  # the repository transaction, +path+ is the relative path from the root of the repository
  # to prepend to each filename.
  #
  # If files should be added to a repo that is already open, the open repo object can be passed
  # as the +repo+ keyword argument, otherwise the repo for this group will be used.
  #
  # If files should be added as part of an existent transaction, the transaction object can be
  # passed as the +txn+ keyword argument, otherwise a new transaction will be created. If the +txn+
  # argument is not nil, the transaction will be commited before returning, otherwise the transaction
  # object will not be commited and so should be commited later on by the caller.
  #
  # Returns a tuple containing a boolean and an array. If the +txn+ argument was nil, the boolean
  # indicates whether the transaction was completed without errors. If the +txn+ argument was not
  # nil, the boolean indicates whether any errors were encountered which mean the caller should not
  # commit the transaction. The array contains any error or warning messages as arrays of arguments
  # (each of which can be passed directly to flash_message from a controller).
  def add_files(files, user, path: '/', repo: nil, txn: nil)
    messages = []
    if repo.nil?
      group.access_repo do |open_repo|
        return add_files(files, user, path: path, repo: open_repo, txn: txn)
      end
    end

    if txn.nil?
      txn = repo.get_transaction(user.user_name)
      commit_txn = true
    else
      commit_txn = false
    end

    revision = repo.get_latest_revision
    assignment_path = Pathname.new(assignment.repository_folder)
    current_path = assignment_path.join(path.gsub(/^\//, '')) # remove leading '/' to make relative path
    new_files = []
    files.each do |f|
      if f.size > MarkusConfigurator.markus_config_max_file_size
        messages << [:error, I18n.t('student.submission.file_too_large',
                             file_name: f.original_filename,
                             max_size: (MarkusConfigurator.markus_config_max_file_size / 1_000_000.00).round(2))]
      elsif f.size == 0
        messages << [:warning, I18n.t('student.submission.empty_file_warning', file_name: f.original_filename)]
      end
      filename = f.original_filename
      if filename.nil?
        messages << [:error, I18n.t('student.submission.invalid_file_name')]
        return false, messages
      end
      subdir_path, filename = File.split(filename)
      filename = sanitize_file_name(filename)
      file_path = current_path.join(subdir_path).join(filename)
      file_path_relative = file_path.relative_path_from(assignment_path).to_s
      file_path = file_path.to_s
      # Sometimes the file pointer of file_object is at the end of the file.
      # In order to avoid empty uploaded files, rewind it to be safe.
      f.rewind
      # Branch on whether the file is new or a replacement
      if revision.path_exists?(file_path)
        txn.replace(file_path, f.read, f.content_type, revision.revision_identifier)
      else
        new_files << file_path_relative
        txn.add(file_path, f.read, f.content_type)
      end
    end
    # check if only required files are allowed for a submission
    required_files = assignment.assignment_files.pluck(:filename)
    if required_files.present? && assignment.only_required_files && (new_files - required_files).present?
      messages << [:error, I18n.t('assignment.upload_file_requirement')]
      return false, messages
    end

    if commit_txn
      success, txn_messages = commit_transaction repo, txn
      [success, messages + txn_messages]
    else
      [true, messages]
    end
  end

  # Delete files in this group's repo. +file_revisions+ should be a Hash mapping file names to
  # the expected revision that contains the file to be deleted. +file_revisions+ can also be an
  # array and if so, the expected revision that contains the file will default to the most recent
  # revision. +user+ is the user that is responsible for the repository transaction, and
  # +path+ is the relative path from the root of the repository to prepend to each filename.
  #
  # If files should be added to a repo that is already open, the open repo object can be passed
  # as the +repo+ keyword argument, otherwise the repo for this group will be used.
  #
  # If files should be added as part of an existent transaction, the transaction object can be
  # passed as the +txn+ keyword argument, otherwise a new transaction will be created. If the +txn+
  # argument is not nil, the transaction will be commited before returning, otherwise the transaction
  # object will not be commited and so should be commited later on by the caller.
  #
  # Returns a tuple containing a boolean and an array. If the +txn+ argument was nil, the boolean
  # indicates whether the transaction was completed without errors. If the +txn+ argument was not
  # nil, the boolean indicates whether any errors were encountered which mean the caller should not
  # commit the transaction. The array contains any error or warning messages as arrays of arguments
  # (each of which can be passed directly to flash_message from a controller).
  def remove_files(file_revisions, user, path: '/', repo: nil, txn: nil)
    messages = []
    if repo.nil?
      group.access_repo do |open_repo|
        return remove_files(file_revisions, user, path: path, repo: open_repo, txn: txn)
      end
    end

    if txn.nil?
      txn = repo.get_transaction(user.user_name)
      commit_txn = true
    else
      commit_txn = false
    end

    assignment_path = Pathname.new(assignment.repository_folder)
    current_path = assignment_path.join(path.gsub(/^\//, ''))

    current_revision = repo.get_latest_revision.revision_identifier

    file_revisions.each do |file_path, revision|
      subdir_path, basename = File.split(file_path)
      basename = sanitize_file_name(basename)
      file_path = current_path.join(subdir_path).join(basename)
      file_path = file_path.to_s
      txn.remove(file_path, revision || current_revision)
    end

    if commit_txn
      success, txn_messages = commit_transaction repo, txn
      [success, messages + txn_messages]
    else
      [true, messages]
    end
  end

  private

  # Helper method that commits a transaction +txn+ in repo +repo+. Returns a boolean and an array
  # where the boolean indicates whether the transaction was commited successfully and an array
  # containing any error or warning messages.
  #
  # Does not attempt to commit the transaction if there are no jobs present to commit.
  def commit_transaction(repo, txn)
    if txn.has_jobs?
      if repo.commit(txn)
        return true, []
      else
        return false, [:error, partial: 'submissions/file_conflicts_list', locals: { conflicts: txn.conflicts }]
      end
    end
    [false, [:warning, I18n.t('student.submission.no_action_detected')]]
  end
end # end class Grouping
