require 'csv'

# Represents an assignment where students submit work to be graded
class Assignment < Assessment
  include AutomatedTestsHelper

  MIN_PEER_REVIEWS_PER_GROUP = 1

  validates :due_date, presence: true

  # this has to be before :peer_reviews or it throws a HasManyThroughOrderError
  has_many :groupings, foreign_key: :assessment_id, inverse_of: :assignment
  has_many :groups, through: :groupings, dependent: :restrict_with_exception

  has_one :assignment_properties,
          dependent: :destroy,
          inverse_of: :assignment,
          foreign_key: :assessment_id,
          autosave: true
  delegate_missing_to :assignment_properties
  accepts_nested_attributes_for :assignment_properties, update_only: true
  validates :assignment_properties, presence: true
  after_initialize :create_associations
  before_save :reset_collection_time
  after_create :update_parent_assignment, if: :is_peer_review?

  # Add assignment_properties to default scope because we almost always want to load an assignment with its properties
  default_scope { includes(:assignment_properties) }

  has_many :criteria,
           -> { order(:position) },
           dependent: :destroy,
           inverse_of: :assignment,
           foreign_key: :assessment_id

  has_many :ta_criteria,
           -> { where(ta_visible: true).order(:position) },
           class_name: 'Criterion',
           dependent: :destroy,
           inverse_of: :assignment,
           foreign_key: :assessment_id

  has_many :peer_criteria,
           -> { where(peer_visible: true).order(:position) },
           class_name: 'Criterion',
           dependent: :destroy,
           inverse_of: :assignment,
           foreign_key: :assessment_id

  has_many :test_groups, dependent: :destroy, inverse_of: :assignment, foreign_key: :assessment_id
  accepts_nested_attributes_for :test_groups, allow_destroy: true, reject_if: ->(attrs) { attrs[:name].blank? }

  has_many :annotation_categories,
           -> { order(:position) },
           class_name: 'AnnotationCategory',
           dependent: :destroy,
           inverse_of: :assignment,
           foreign_key: :assessment_id

  has_many :criterion_ta_associations, dependent: :destroy, foreign_key: :assessment_id, inverse_of: :assignment

  has_many :assignment_files, dependent: :destroy, inverse_of: :assignment, foreign_key: :assessment_id
  accepts_nested_attributes_for :assignment_files, allow_destroy: true
  validates_associated :assignment_files

  # Assignments can now refer to themselves, where this is null if there
  # is no parent (the same holds for the child peer reviews)
  belongs_to :parent_assignment,
             class_name: 'Assignment', optional: true, inverse_of: :pr_assignment, foreign_key: :parent_assessment_id
  has_one :pr_assignment,
          class_name: 'Assignment',
          dependent: :destroy,
          foreign_key: :parent_assessment_id,
          inverse_of: :parent_assignment
  has_many :peer_reviews, through: :groupings
  has_many :pr_peer_reviews, through: :parent_assignment, source: :peer_reviews

  has_many :current_submissions_used, through: :groupings,
                                      source: :current_submission_used

  has_many :ta_memberships, through: :groupings
  has_many :student_memberships, through: :groupings

  has_many :submissions, through: :groupings

  has_many :notes, as: :noteable, dependent: :destroy

  has_many :exam_templates, dependent: :destroy, inverse_of: :assignment, foreign_key: :assessment_id

  has_many :starter_file_groups, dependent: :destroy, inverse_of: :assignment, foreign_key: :assessment_id

  has_many :tas, -> { distinct }, through: :ta_memberships, source: :role

  before_save do
    @prev_assessment_section_property_ids = assessment_section_properties.ids
    @prev_assignment_file_ids = assignment_files.ids
  end

  after_create :create_autotest_dirs
  after_save_commit :update_repo_permissions
  after_save_commit :update_repo_required_files

  after_save :update_assigned_tokens
  after_save :create_peer_review_assignment_if_not_exist

  has_one :submission_rule, dependent: :destroy, inverse_of: :assignment, foreign_key: :assessment_id
  accepts_nested_attributes_for :submission_rule, allow_destroy: true
  validates_associated :submission_rule
  validates :submission_rule, presence: true
  validate :courses_should_match

  BLANK_MARK = ''.freeze

  # Copy of API::AssignmentController without selected attributes and order changed
  # to put first the 4 required fields
  DEFAULT_FIELDS = [:short_identifier, :description,
                    :due_date, :message, :group_min, :group_max, :tokens_per_period,
                    :allow_web_submits, :student_form_groups, :remark_due_date,
                    :remark_message, :assign_graders_to_criteria, :enable_test,
                    :enable_student_tests, :allow_remarks,
                    :display_grader_names_to_students,
                    :display_median_to_students, :group_name_autogenerated,
                    :is_hidden, :visible_on, :visible_until, :vcs_submit, :has_peer_review].freeze

  ASSESSMENT_FIELDS = [:short_identifier, :description, :due_date, :message, :is_hidden, :visible_on,
                       :visible_until].freeze

  ASSIGNMENT_PROPERTIES_FIELDS = [:group_min, :group_max, :tokens_per_period,
                                  :allow_web_submits, :student_form_groups, :remark_due_date,
                                  :remark_message, :assign_graders_to_criteria, :enable_test,
                                  :enable_student_tests, :allow_remarks,
                                  :display_grader_names_to_students,
                                  :display_median_to_students, :group_name_autogenerated,
                                  :vcs_submit, :has_peer_review].freeze

  STARTER_FILES_DIR = (
    Settings.file_storage.starter_files || File.join(Settings.file_storage.default_root_path, 'starter_files')
  ).freeze

  # Set the default order of assignments: in ascending order of date (due_date)
  default_scope { order(:due_date, :id) }

  # Are we past all due_dates and section due_dates for this assignment?
  # This does not take extensions into consideration.
  def past_all_due_dates?
    # If no section due dates /!\ do not check empty? it could be wrong
    return false if !due_date.nil? && Time.current < due_date
    return false if assessment_section_properties.any? { |sec| !sec.due_date.nil? && Time.current < sec.due_date }

    true
  end

  # Return an array with names of sections past
  def section_names_past_due_date
    if !self.section_due_dates_type && !due_date.nil? && Time.current > due_date
      return []
    end

    sections_past = []
    self.assessment_section_properties.each do |d|
      if !d.due_date.nil? && Time.current > d.due_date
        sections_past << d.section.name
      end
    end

    sections_past
  end

  def upcoming(current_role)
    grouping = current_role.accepted_grouping_for(self.id)
    due_date = grouping&.collection_date
    return !past_collection_date?(current_role.section) if due_date.nil?
    due_date > Time.current
  end

  # Whether or not this grouping is past its due date for this assignment.
  def grouping_past_due_date?(grouping)
    return past_all_due_dates? if grouping.nil?

    date = grouping.due_date
    !date.nil? && Time.current > date
  end

  def section_due_date(section)
    unless section_due_dates_type && section
      return due_date
    end

    AssessmentSectionProperties.due_date_for(section, self)
  end

  # Return the start_time for +section+ if it is not nil, otherwise return this
  # assignments start_time instead.
  def section_start_time(section)
    return start_time unless section_due_dates_type

    section&.assessment_section_properties&.find_by(assessment: self)&.start_time || start_time
  end

  # Calculate the latest due date among all sections for the assignment.
  def latest_due_date
    return due_date unless section_due_dates_type
    due_dates = assessment_section_properties.map(&:due_date) << due_date
    due_dates.compact.max
  end

  # Return collection date for all groupings as a hash mapping grouping_id to collection date.
  def all_grouping_collection_dates
    submission_rule_hours = submission_rule.periods.pluck('periods.hours').sum.hours
    no_penalty = Set.new(groupings.joins(:extension).where('extensions.apply_penalty': false).ids)
    collection_dates = Hash.new { |h, k| h[k] = due_date + submission_rule_hours }
    all_grouping_due_dates.each do |grouping_id, grouping_due_date|
      if no_penalty.include? grouping_id
        collection_dates[grouping_id] = grouping_due_date
      else
        collection_dates[grouping_id] = grouping_due_date + submission_rule_hours
      end
    end
    collection_dates
  end

  # Return due date for all groupings as a hash mapping grouping_id to due date.
  def all_grouping_due_dates
    section_due_dates = groupings.joins(inviter: [section: :assessment_section_properties])
                                 .where('assessment_section_properties.assessment_id': id)
                                 .pluck('groupings.id', 'assessment_section_properties.due_date')

    grouping_extensions = groupings.joins(:extension)
                                   .pluck(:id, :time_delta)

    due_dates = Hash.new { |h, k| h[k] = due_date }
    section_due_dates.each do |grouping_id, sec_due_date|
      due_dates[grouping_id] = sec_due_date unless sec_due_date.nil?
    end
    grouping_extensions.each do |grouping_id, ext|
      due_dates[grouping_id] += ext
    end
    due_dates
  end

  # checks if the due date for +section+ has passed for this assignment
  # or if the main due date has passed if +section+ is nil.
  def past_collection_date?(section = nil)
    Time.current > submission_rule.calculate_collection_time(section)
  end

  def past_all_collection_dates?
    if section_due_dates_type && course.sections.any?
      course.sections.all? do |s|
        past_collection_date? s
      end
    else
      past_collection_date?
    end
  end

  def past_remark_due_date?
    !remark_due_date.nil? && Time.current > remark_due_date
  end

  # Return true if this is a group assignment; false otherwise
  def group_assignment?
    group_max > 1
  end

  # Return all released marks for this assignment
  def released_marks
    submissions.joins(:results).where(results: { released_to_students: true })
  end

  # Returns the group by the user for this assignment. If pending=true,
  # it will return the group that the user has a pending invitation to.
  # Returns nil if user does not have a group for this assignment, or if it is
  # not a group assignment
  def group_by(uid, pending: false)
    return unless group_assignment?

    # condition = "memberships.user_id = ?"
    # condition += " and memberships.status != 'rejected'"
    # add non-pending status clause to condition
    # condition += " and memberships.status != 'pending'" unless pending
    # groupings.first(include: :memberships, conditions: [condition, uid]) #FIXME: needs schema update

    # FIXME: needs to be rewritten using a proper query...
    Role.find(uid.id).accepted_grouping_for(id)
  end

  def display_for_note
    short_identifier
  end

  # Returns the maximum possible mark for a particular assignment as a float
  # The sum is converted from a BigDecimal to a float so that when it is passed to the frontend it is not a string
  def max_mark(user_visibility = :ta_visible)
    Float(criteria.where(user_visibility => true, bonus: false).sum(:max_mark).round(2))
  end

  # Returns a boolean indicating whether marking has started for at least
  # one submission for this assignment.  Only the most recently collected
  # submissions are considered.
  def marking_started?
    Result.joins(:marks, submission: :grouping)
          .where(groupings: { assessment_id: id },
                 submissions: { submission_version_used: true })
          .where.not(marks: { mark: nil })
          .any?
  end

  # Returns a list of total marks for each complete result for this assignment.
  # There is one mark per grouping (not per student). Does NOT include:
  #   - groupings with no submission
  #   - incomplete results
  #   - original results when a grouping has submitted a remark request that is not complete
  def completed_result_marks
    return @completed_result_marks if defined? @completed_result_marks

    completed_result_ids = self.current_results.where(marking_state: Result::MARKING_STATES[:complete]).ids
    @completed_result_marks = Result.get_total_marks(completed_result_ids).values.sort
  end

  def all_grouping_data
    student_data = self.course
                       .students
                       .joins(:user)
                       .pluck_to_hash(:id, :user_name, :first_name, :last_name, :hidden)
    students = student_data.map do |s|
      [s[:user_name], s.merge(_id: s[:id], assigned: false)]
    end.to_h
    grouping_data = self
                    .groupings
                    .joins(:group)
                    .left_outer_joins(:extension)
                    .left_outer_joins(non_rejected_student_memberships: [role: :user])
                    .left_outer_joins(inviter: :section)
                    .pluck_to_hash('groupings.id',
                                   'groupings.instructor_approved',
                                   'groups.group_name',
                                   'users.user_name',
                                   'roles.hidden',
                                   'memberships.membership_status',
                                   'sections.name',
                                   'extensions.id',
                                   'extensions.time_delta',
                                   'extensions.apply_penalty',
                                   'extensions.note')

    members = Hash.new { |h, k| h[k] = [] }
    grouping_data.each do |data|
      if data['users.user_name']
        members[data['groupings.id']] << [data['users.user_name'], data['memberships.membership_status'],
                                          data['roles.hidden']]
        students[data['users.user_name']][:assigned] = true
      end
    end
    ids = Set.new
    groupings = grouping_data.filter_map do |data|
      next if ids.include? data['groupings.id'] # distinct on the query doesn't seem to work

      ids << data['groupings.id']
      if data['extensions.time_delta'].nil?
        extension_data = {}
      elsif assignment.is_timed
        extension_data = AssignmentProperties.duration_parts data['extensions.time_delta']
      else
        extension_data = Extension.to_parts data['extensions.time_delta']
      end
      extension_data[:note] = data['extensions.note'] || ''
      extension_data[:apply_penalty] = data['extensions.apply_penalty'] || false
      extension_data[:id] = data['extensions.id']
      extension_data[:grouping_id] = data['groupings.id']
      {
        _id: data['groupings.id'],
        instructor_approved: data['groupings.instructor_approved'],
        group_name: data['groups.group_name'],
        extension: extension_data,
        members: members[data['groupings.id']],
        section: data['sections.name'] || ''
      }
    end

    {
      students: students.values,
      groups: groupings,
      exam_templates: assignment.exam_templates
    }
  end

  def add_group(new_group_name = nil)
    if group_name_autogenerated
      group = self.course.groups.new
      group.save(validate: false)
      group.group_name = group.get_autogenerated_group_name
      group.save
    else
      return if new_group_name.nil?
      if (group = self.course.groups.where(group_name: new_group_name).first)
        unless groupings.where(group_id: group.id).first.nil?
          raise "Group #{new_group_name} already exists"
        end
      else
        group = Group.create(group_name: new_group_name, course: self.course)
      end
    end
    Grouping.create(group: group, assignment: self)
  end

  def add_group_api(new_group_name = nil, members = [])
    members ||= []

    Group.transaction do
      if new_group_name.nil?
        if members.length == 1 && self.group_max == 1 && !self.is_timed
          student_user_name = members.first
          group = Group.find_or_initialize_by(group_name: student_user_name, course: self.course) do |g|
            g.repo_name = student_user_name
          end
        elsif group_name_autogenerated
          group = course.groups.new
          group.save(validate: false)
          group.group_name = group.get_autogenerated_group_name
        else
          raise 'A group name was not provided'
        end
      elsif (group = self.course.groups.where(group_name: new_group_name).first)
        unless groupings.where(group_id: group.id).first.nil?
          raise "Group #{new_group_name} already exists"
        end
      else
        group = Group.create(group_name: new_group_name, course: self.course, repo_name: new_group_name)
      end

      group.save!

      if self.groupings.exists?(group_id: group.id)
        raise "Group '#{group.group_name}' is already part of this assignment"
      end
      grouping = Grouping.create!(group: group, assignment: self)

      unless members.empty?
        students = self.course.students
                       .joins(:user)
                       .where(users: { user_name: members })
                       .pluck(:user_name, :id)
                       .to_h

        members.each_with_index do |user_name, index|
          student_id = students[user_name] || raise("Student #{user_name} not found")

          grouping.student_memberships.create!(
            role_id: student_id,
            membership_status: StudentMembership::STATUSES[index.zero? ? :inviter : :accepted]
          )
        end
      end
      group
    end
  rescue ActiveRecord::RecordInvalid => e
    raise "Operation failed: #{e.record.errors.full_messages.join(', ')}"
  end

  # Clones the Groupings from the assignment with id assessment_id
  # into self.  Destroys any previously existing Groupings associated
  # with this Assignment
  def clone_groupings_from(assessment_id)
    warnings = []
    original_assignment = Assignment.find(assessment_id)
    self.transaction do
      self.group_min = original_assignment.group_min
      self.group_max = original_assignment.group_max
      self.student_form_groups = original_assignment.student_form_groups
      self.group_name_autogenerated = original_assignment.group_name_autogenerated
      self.groupings.destroy_all
      self.assignment_properties.save
      self.save
      self.reload
      original_assignment.groupings.each do |g|
        active_student_memberships = g.accepted_student_memberships.reject { |m| m.role.hidden }
        if active_student_memberships.empty?
          warnings << I18n.t('groups.clone_warning.no_active_students', group: g.group.group_name)
          next
        end
        active_ta_memberships = g.ta_memberships.reject { |m| m.role.hidden }
        grouping = Grouping.new
        grouping.group_id = g.group_id
        grouping.assessment_id = self.id
        grouping.instructor_approved = g.instructor_approved
        unless grouping.save
          warnings << I18n.t('groups.clone_warning.other',
                             group: g.group.group_name, error: grouping.errors.messages)
          next
        end
        all_memberships = active_student_memberships + active_ta_memberships
        Repository.get_class.update_permissions_after(only_on_request: true) do
          all_memberships.each do |m|
            membership = Membership.new
            membership.role_id = m.role_id
            membership.type = m.type
            membership.membership_status = m.membership_status
            unless grouping.memberships << membership
              grouping.memberships.delete(membership)
              warnings << I18n.t('groups.clone_warning.no_member',
                                 member: m.role.user_name,
                                 group: g.group.group_name, error: membership.errors.messages)
            end
          end
        end
      end
    end

    warnings
  end

  def grouped_students
    student_memberships.map(&:role)
  end

  def ungrouped_students
    course.students.where(hidden: false) - grouped_students
  end

  def valid_groupings
    groupings.includes(student_memberships: :role).select(&:is_valid?)
  end

  def invalid_groupings
    groupings - valid_groupings
  end

  def assigned_groupings
    groupings.joins(:ta_memberships).includes(ta_memberships: :role).uniq
  end

  def unassigned_groupings
    groupings - assigned_groupings
  end

  # Get a list of repo checkout client commands to be used for scripting
  def get_repo_checkout_commands(ssh_url: false)
    self.groupings.includes(:group, :current_submission_used).filter_map do |grouping|
      submission = grouping.current_submission_used
      next if submission&.revision_identifier.nil?
      url = ssh_url ? grouping.group.repository_ssh_access_url : grouping.group.repository_external_access_url
      Repository.get_class.get_checkout_command(url,
                                                submission.revision_identifier,
                                                grouping.group.group_name, repository_folder)
    end
  end

  # Get a list of group_name, repo-url pairs
  def get_repo_list(ssh: false)
    CSV.generate do |csv|
      self.groupings.includes(:group).find_each do |grouping|
        group = grouping.group
        data = [group.group_name, group.repository_external_access_url]
        data << group.repository_ssh_access_url if ssh
        csv << data
      end
    end
  end

  # Generate JSON summary of grades for this assignment
  # for the current user. The user should be an instructor or TA.
  def summary_json(user)
    return {} unless user.instructor? || user.ta?
    lti_deployments = []

    if user.instructor?
      groupings = self.groupings
      graders = groupings.joins(tas: :user)
                         .pluck_to_hash(:id, 'users.user_name', 'users.first_name', 'users.last_name')
                         .group_by { |x| x[:id] }
      assigned_criteria = nil
      lti_deployments = LtiLineItem.where(assessment_id: self.id)
                                   .joins(lti_deployment: :lti_client)
                                   .pluck_to_hash('lti_deployments.id',
                                                  'lti_clients.host',
                                                  'lti_deployments.lms_course_name')
      lti_deployments.each { |deployment| deployment.transform_keys! { |key| key.to_s.split('.')[-1] } }
    else
      groupings = self.groupings
                      .joins(:memberships)
                      .where('memberships.role_id': user.id)
      graders = {}
      if self.assign_graders_to_criteria
        assigned_criteria = user.criterion_ta_associations
                                .where(assessment_id: self.id)
                                .pluck(:criterion_id)
      else
        assigned_criteria = nil
      end
    end
    grouping_data = groupings.joins(:group)
                             .left_outer_joins(inviter: :section)
                             .pluck_to_hash(:id, 'groups.group_name', 'sections.name')
                             .group_by { |x| x[:id] }
    members = Grouping.joins(accepted_students: :user)
                      .where(id: groupings)
                      .pluck_to_hash(:id, 'users.user_name', 'users.first_name', 'users.last_name', 'roles.hidden')
                      .group_by { |x| x[:id] }
    tag_data = groupings
               .joins(:tags)
               .pluck_to_hash(:id, 'tags.name')
               .group_by { |h| h[:id] }

    collection_dates = all_grouping_collection_dates
    all_results = current_results.where('groupings.id': groupings.ids).order(:id)
    results_data = all_results.pluck('groupings.id').zip(all_results.includes(:marks)).to_h
    result_ids = all_results.ids
    extra_marks_hash = Result.get_total_extra_marks(result_ids, max_mark: max_mark)

    hide_unassigned = user.ta? && hide_unassigned_criteria

    criteria_shown = Set.new
    max_mark = 0

    selected_criteria = user.instructor? ? self.criteria : self.ta_criteria
    criteria_columns = selected_criteria.filter_map do |crit|
      unassigned = !assigned_criteria.nil? && assigned_criteria.exclude?(crit.id)
      next if hide_unassigned && unassigned

      max_mark += crit.max_mark unless crit.bonus?
      accessor = crit.id
      criteria_shown << accessor
      {
        Header: crit.bonus? ? "#{crit.name} (#{Criterion.human_attribute_name(:bonus)})" : crit.name,
        accessor: "criteria.#{accessor}",
        className: unassigned ? 'number unassigned' : 'number',
        headerClassName: unassigned ? 'unassigned' : ''
      }
    end

    final_data = groupings.map do |g|
      result = results_data[g.id]
      has_remark = !result&.remark_request_submitted_at.nil?
      if user.ta? && anonymize_groups
        group_name = "#{Group.model_name.human} #{g.id}"
        section = ''
        group_members = []
      else
        group_name = grouping_data[g.id][0]['groups.group_name']
        section = grouping_data[g.id][0]['sections.name']
        group_members = members.fetch(g.id, [])
                               .map do |s|
          [s['users.user_name'], s['users.first_name'], s['users.last_name'], s['roles.hidden']]
        end
      end

      tag_info = tag_data.fetch(g.id, [])
                         .pluck('tags.name')
      criteria = result.nil? ? {} : result.mark_hash.slice(*criteria_shown)
      criteria.transform_values! { |data| data[:mark] }
      extra_mark = extra_marks_hash[result&.id]
      {
        group_name: group_name,
        section: section,
        members: group_members,
        tags: tag_info,
        graders: graders.fetch(g.id, [])
                        .map { |s| [s['users.user_name'], s['users.first_name'], s['users.last_name']] },
        marking_state: marking_state(has_remark,
                                     result&.marking_state,
                                     result&.released_to_students,
                                     collection_dates[g.id]),
        final_grade: [criteria.values.compact.sum + (extra_mark || 0), 0].max,
        criteria: criteria,
        max_mark: max_mark,
        result_id: result&.id,
        submission_id: result&.submission_id,
        total_extra_marks: extra_mark
      }
    end

    { data: final_data,
      criteriaColumns: criteria_columns,
      numAssigned: self.get_num_assigned(user.instructor? ? nil : user.id),
      numMarked: self.get_num_marked(user.instructor? ? nil : user.id),
      enableTest: self.enable_test,
      ltiDeployments: lti_deployments }
  end

  # Generates the summary of the most test results associated with an assignment.
  def summary_test_results(group_names = nil)
    latest_test_run_by_grouping = TestRun.group('grouping_id').select('MAX(created_at) as test_runs_created_at',
                                                                      'grouping_id')
                                         .where.not(submission_id: nil)
                                         .to_sql

    latest_test_runs = TestRun
                       .joins(grouping: :group)
                       .joins("INNER JOIN (#{latest_test_run_by_grouping}) latest_test_run_by_grouping \
            ON latest_test_run_by_grouping.grouping_id = test_runs.grouping_id \
            AND latest_test_run_by_grouping.test_runs_created_at = test_runs.created_at")
                       .select('id', 'test_runs.grouping_id', 'groups.group_name')
                       .to_sql

    query = self.test_groups.joins(test_group_results: :test_results)
                .joins("INNER JOIN (#{latest_test_runs}) latest_test_runs \
              ON test_group_results.test_run_id = latest_test_runs.id")

    # Optionally - filters specific groups if provided
    query = query.where('latest_test_runs.group_name': group_names) if group_names.present?

    query.select('test_groups.name',
                 'test_groups.id as test_groups_id',
                 'latest_test_runs.group_name',
                 'test_results.name as test_result_name',
                 'test_results.status',
                 'test_results.marks_earned',
                 'test_results.marks_total',
                 :output, :extra_info, :error_type)
  end

  # Generate a JSON summary of the most recent test results associated with an assignment.
  def summary_test_result_json
    self.summary_test_results.group_by(&:group_name).transform_values do |grouping|
      grouping.group_by(&:name)
    end.to_json
  end

  # Generate a CSV summary of the most recent test results associated with an assignment.
  def summary_test_result_csv
    results = {}
    headers = Set.new
    summary_test_results = self.summary_test_results.as_json

    summary_test_results.each do |test_result|
      header = "#{test_result['name']}:#{test_result['test_result_name']}"

      if results.key?(test_result['group_name'])
        results[test_result['group_name']][header] = test_result['status']
      else
        results[test_result['group_name']] = { header => test_result['status'] }
      end

      headers << header
    end
    headers = headers.sort

    CSV.generate do |csv|
      csv << [nil, *headers]

      results.sort_by(&:first).each do |(group_name, _test_group)|
        row = [group_name]

        headers.each do |header|
          if results[group_name].key?(header)
            row << results[group_name][header]
          else
            row << nil
          end
        end
        csv << row
      end
    end
  end

  # Generate CSV summary of grades for this assignment
  # for the current user. The user should be an instructor or TA.
  def summary_csv(role)
    return '' unless role.instructor?

    if role.instructor?
      groupings = self.groupings
                      .includes(:group,
                                current_result: :marks)
    else
      groupings = self.groupings
                      .includes(:group,
                                current_result: :marks)
                      .joins(:memberships)
                      .where('memberships.role_id': role.id)
    end

    students = Student.includes(:accepted_groupings, :section)
                      .where('accepted_groupings.assessment_id': self.id)
                      .joins(:user)
                      .order('users.user_name')

    first_row = [Group.human_attribute_name(:group_name)] +
      Student::CSV_ORDER.map { |field| User.human_attribute_name(field) } +
      [I18n.t('results.total_mark')]

    second_row = [' '] * Student::CSV_ORDER.length + [Assessment.human_attribute_name(:max_mark), self.max_mark]

    headers = [first_row, second_row]

    self.ta_criteria.each do |crit|
      headers[0] << (crit.bonus? ? "#{crit.name} (#{Criterion.human_attribute_name(:bonus)})" : crit.name)
      headers[1] << crit.max_mark
    end
    headers[0] << 'Bonus/Deductions'
    headers[1] << ''

    result_ids = groupings.pluck('results.id').uniq.compact
    subtotals = Result.get_subtotals(result_ids)
    extra_marks_hash = Result.get_total_extra_marks(result_ids, max_mark: max_mark, subtotals: subtotals)
    total_marks_hash = Result.get_total_marks(result_ids, subtotals: subtotals, extra_marks: extra_marks_hash)
    CSV.generate do |csv|
      csv << headers[0]
      csv << headers[1]

      students.each do |student|
        # filtered to keep only the groupings for this assignment when defining students above
        g = student.accepted_groupings.first
        result = g&.current_result
        marks = result.nil? ? {} : result.mark_hash
        other_info = Student::CSV_ORDER.map { |field| student.public_send(field) }
        row = [g&.group&.group_name] + other_info
        if result.nil?
          row += Array.new(2 + self.ta_criteria.count, nil)
        else
          row << total_marks_hash[result.id]
          row += self.ta_criteria.map { |crit| marks[crit.id]&.[](:mark) }
          row << extra_marks_hash[result.id]
        end
        csv << row
      end
    end
  end

  # Returns an array of [mark, max_mark].
  def get_marks_list(submission)
    criteria.map do |criterion|
      mark = submission.get_latest_result.marks.find_by(criterion: criterion)
      [mark.nil? || mark.mark.nil? ? '' : mark.mark,
       criterion.max_mark]
    end
  end

  def next_criterion_position
    # We're using count here because this fires off a DB query, thus
    # grabbing the most up-to-date count of the criteria.
    criteria.exists? ? criteria.last.position + 1 : 1
  end

  # Returns all the submissions that have not been graded (completed).
  # Note: This assumes that every submission has at least one result.
  def ungraded_submission_results
    current_results.where('results.marking_state': Result::MARKING_STATES[:incomplete])
  end

  def is_criteria_mark?(ta_id)
    assign_graders_to_criteria && self.criterion_ta_associations.where(ta_id: ta_id).any?
  end

  def get_num_assigned(ta_id = nil, bulk: false)
    if ta_id.nil?
      groupings.size
    elsif bulk
      cache_ta_results.dig(ta_id, :total_results)&.size || 0
    else
      ta_memberships.where(role_id: ta_id).size
    end
  end

  def get_num_collected(ta_id = nil)
    if ta_id.nil?
      groupings.where(is_collected: true).count
    else
      groupings.joins(:ta_memberships)
               .where('groupings.is_collected': true)
               .where('memberships.role_id': ta_id).count
    end
  end

  def get_num_valid
    groupings.includes(:non_rejected_student_memberships, current_submission_used: :submitted_remark)
             .to_a
             .count(&:is_valid?)
  end

  def marked_result_ids_for(ta_id)
    cache_ta_results.dig(ta_id, :marked_result_ids) || []
  end

  def cache_ta_results
    return @cache_ta_results if defined? @cache_ta_results

    data = current_results.joins(grouping: :tas).pluck('tas.id', 'results.id', 'results.marking_state')
    # Group results by TA ID
    grouped_data = data.group_by { |ta_id, _result_id, _marking_state| ta_id }
    # map ta_ids to criteria_ids
    ta_to_criteria = self.criterion_ta_associations
                         .pluck([:ta_id, :criterion_id])
                         .group_by { |ta_id, _| ta_id }
                         .transform_values { |pairs| pairs.map { |_, criterion_id| criterion_id } }

    @cache_ta_results = grouped_data.map do |ta_id, results|
      total_results = results.map { |_, result_id, _| result_id }

      if self.assign_graders_to_criteria
        # Get the list of criteria IDs assigned to this TA
        assigned_criteria_ids = ta_to_criteria[ta_id] || []
        criteria_count = assigned_criteria_ids.size

        if criteria_count == 0
          # If the TA has no assigned criteria, fallback to using marking_state to determine marked results
          complete_results = results.select do |_, _, marking_state|
            marking_state == Result::MARKING_STATES[:complete]
          end
          marked_result_ids = complete_results.map { |_, result_id, _| result_id }
        else
          # Count results where all assigned criteria have been marked
          marked_result_ids = Result.joins(:marks)
                                    .where(id: total_results, marks: { criterion_id: assigned_criteria_ids })
                                    .where.not(marks: { mark: nil })
                                    .group('results.id')
                                    .having('count(marks.id) = ?', criteria_count)
                                    .pluck('results.id')
        end
      else
        # Grading not by criterion: count only completed results
        marked_result_ids = results.select { |_, _, marking_state| marking_state == Result::MARKING_STATES[:complete] }
                                   .map { |_, result_id, _| result_id }
      end
      [ta_id, { total_results: results, marked_result_ids: marked_result_ids }]
    end.to_h
  end

  def get_num_marked(ta_id = nil, bulk: false)
    if bulk
      return cache_ta_results.dig(ta_id, :marked_result_ids)&.size || 0
    end
    if ta_id.nil?
      self.current_results.where(marking_state: Result::MARKING_STATES[:complete]).count
    elsif is_criteria_mark?(ta_id)
      assigned_criteria = self.criteria.joins(:criterion_ta_associations)
                              .where(criterion_ta_associations: { ta_id: ta_id })

      self.current_results.joins(:marks, grouping: :ta_memberships)
          .where('memberships.role_id': ta_id, 'marks.criterion_id': assigned_criteria.ids)
          .where.not('marks.mark': nil)
          .group('results.id')
          .having('count(*) = ?', assigned_criteria.count)
          .length
    else
      self.current_results.joins(grouping: :ta_memberships)
          .where('memberships.role_id': ta_id, 'results.marking_state': 'complete')
          .count
    end
  end

  # Batch load TA stats for multiple assignments to avoid N+1 queries.
  # Returns { assignment_id => { num_assigned: Integer, num_marked: Integer } }
  def self.batch_ta_stats(assignments, ta_id)
    return {} if ta_id.nil? || assignments.empty?

    assignment_ids = assignments.map(&:id)

    # Query 1: Count assigned groupings per assignment
    assigned_counts = TaMembership
                      .joins(:grouping)
                      .where(role_id: ta_id, groupings: { assessment_id: assignment_ids })
                      .group('groupings.assessment_id')
                      .count

    # Identify criteria-based assignments for this TA
    criteria_assignment_ids = CriterionTaAssociation
                              .joins(:criterion)
                              .where(ta_id: ta_id, criteria: { assessment_id: assignment_ids })
                              .distinct
                              .pluck('criteria.assessment_id')

    criteria_based_ids = assignments
                         .select { |a| a.assign_graders_to_criteria && criteria_assignment_ids.include?(a.id) }
                         .map(&:id)

    regular_ids = assignment_ids - criteria_based_ids

    # Query 2: Count marked results for non-criteria-based assignments
    marked_counts = if regular_ids.any?
                      Result
                        .joins(submission: { grouping: :ta_memberships })
                        .where(
                          submissions: { submission_version_used: true },
                          memberships: { role_id: ta_id },
                          groupings: { assessment_id: regular_ids },
                          marking_state: Result::MARKING_STATES[:complete]
                        )
                        .group('groupings.assessment_id')
                        .count
                    else
                      {}
                    end

    # Build result hash
    result = {}
    assignments.each do |a|
      num_marked = if criteria_based_ids.include?(a.id)
                     a.get_num_marked(ta_id) # Fall back for criteria-based
                   else
                     marked_counts[a.id] || 0
                   end
      result[a.id] = {
        num_assigned: assigned_counts[a.id] || 0,
        num_marked: num_marked
      }
    end
    result
  end

  def get_num_annotations(ta_id = nil)
    if ta_id.nil?
      num_annotations_all
    else
      # uniq is required since entries are doubled if there is a remark request
      Submission.joins(:annotations, :current_result, grouping: :ta_memberships)
                .where(submissions: { submission_version_used: true },
                       memberships: { role_id: ta_id },
                       results: { marking_state: Result::MARKING_STATES[:complete] },
                       groupings: { assessment_id: self.id })
                .select('annotations.id').uniq.size
    end
  end

  # Count annotations on all results for this assignment, including remark requests
  def num_annotations_all
    groupings = Grouping.arel_table
    submissions = Submission.arel_table
    subs = Submission.joins(:grouping)
                     .where(groupings[:assessment_id].eq(id)
                     .and(submissions[:submission_version_used].eq(true)))

    res = Result.where(submission_id: subs.pluck(:id), remark_request_submitted_at: nil)
    filtered_subs = subs.where(id: res.pluck(:submission_id))
    Annotation.joins(:submission_file)
              .where(submission_files:
                  { submission_id: filtered_subs.pluck(:id) }).size
  end

  def average_annotations(ta_id = nil)
    num_marked = get_num_marked(ta_id)
    avg = 0
    if num_marked != 0
      num_annotations = get_num_annotations(ta_id)
      avg = num_annotations.to_f / num_marked
    end
    avg.round(2)
  end

  # Returns the groupings of this assignment associated with the given section
  def section_groupings(section)
    groupings.select do |grouping|
      grouping.section.id == section.id
    end
  end

  def has_a_collected_submission?
    submissions.exists?(submission_version_used: true)
  end

  # Returns the groupings of this assignment that have no associated section
  def sectionless_groupings
    groupings.select do |grouping|
      grouping.inviter.present? &&
          !grouping.inviter.has_section?
    end
  end

  # Query for all current results for this assignment
  def current_results
    # The timestamps of all current results. This duplicates #non_pr_results,
    # except it renames the groupings table to avoid a name conflict with the second query below.
    subquery = Result.joins('INNER JOIN submissions AS _submissions ON results.submission_id = _submissions.id ' \
                            'INNER JOIN groupings AS _groupings ON _submissions.grouping_id = _groupings.id')
                     .where('_groupings.assessment_id': id, '_submissions.submission_version_used': true)
                     .where.missing(:peer_reviews)
                     .group('_groupings.id')
                     .select('_groupings.id AS grouping_id', 'MAX(results.created_at) AS results_created_at').to_sql

    Result.joins(:grouping)
          .joins("INNER JOIN (#{subquery}) sub ON groupings.id = sub.grouping_id AND " \
                 'results.created_at = sub.results_created_at')
  end

  def current_remark_results
    self.current_results.where.not('results.remark_request_submitted_at' => nil)
  end

  # Query for all non-peer review results for this assignment (for the current submissions)
  def non_pr_results
    Result.joins(:grouping)
          .where('groupings.assessment_id': id, 'submissions.submission_version_used': true)
          .where.missing(:peer_reviews)
  end

  # Returns true if this is a peer review, meaning it has a parent assignment,
  # false otherwise.
  def is_peer_review?
    !parent_assessment_id.nil?
  end

  # Returns true if this is a parent assignment that has a child peer review
  # assignment.
  def has_peer_review_assignment?
    !pr_assignment.nil?
  end

  def create_peer_review_assignment_if_not_exist
    return unless self.has_peer_review && Assignment.where(parent_assessment_id: self.id).empty?
    peerreview_assignment = Assignment.new
    peerreview_assignment.parent_assignment = self
    peerreview_assignment.course = self.course
    peerreview_assignment.token_period = 1
    peerreview_assignment.non_regenerating_tokens = false
    peerreview_assignment.unlimited_tokens = false
    peerreview_assignment.short_identifier = short_identifier + '_pr'
    peerreview_assignment.repository_folder = peerreview_assignment.short_identifier
    peerreview_assignment.description = description
    peerreview_assignment.due_date = due_date
    peerreview_assignment.is_hidden = true
    peerreview_assignment.message = message

    # We do not want to have the database in an inconsistent state, so we
    # need to have the database rollback the 'has_peer_review' column to
    # be false
    return if peerreview_assignment.save
    raise ActiveRecord::Rollback
  end

  ### REPO ###

  def starter_file_path
    File.join(STARTER_FILES_DIR, self.id.to_s)
  end

  def default_starter_file_group
    default = starter_file_groups.find_by(id: self.default_starter_file_group_id)
    default.nil? ? starter_file_groups.order(:id).first : default
  end

  def starter_file_mappings
    groupings.joins(:group, grouping_starter_file_entries: [starter_file_entry: :starter_file_group])
             .pluck_to_hash('groups.group_name as group_name',
                            'starter_file_groups.name as starter_file_group_name',
                            'starter_file_entries.path as starter_file_entry_path')
  end

  def sample_starter_file_entries
    case self.starter_file_type
    when 'simple'
      default_starter_file_group&.starter_file_entries || []
    when 'sections'
      section = Section.find_by(id: self.course.students.distinct.pluck(:section_id).sample)
      sf_group = section&.starter_file_group_for(self) || default_starter_file_group
      sf_group&.starter_file_entries || []
    when 'shuffle'
      self.starter_file_groups.includes(:starter_file_entries).filter_map do |g|
        StarterFileEntry.find_by(id: g.starter_file_entries.ids.sample)
      end
    when 'group'
      StarterFileGroup.find_by(id: self.starter_file_groups.ids.sample)&.starter_file_entries || []
    else
      raise "starter_file_type is invalid: #{self.starter_file_type}"
    end
  end

  # Yield an open repo for each grouping of this assignment, then yield again for each repo that raised an exception, to
  # try to mitigate concurrent accesses to those repos.
  def each_group_repo(&block)
    failed_groupings = []
    self.groupings.each do |grouping|
      grouping.access_repo(&block)
    rescue StandardError
      # in the event of a concurrent repo modification, retry later
      failed_groupings << grouping
    end
    failed_groupings.each do |grouping|
      grouping.access_repo(&block)
    rescue StandardError
      # give up
    end
  end

  ### /REPO ###

  def autotest_path
    File.join(TestRun::SETTINGS_FILES_DIR, self.id.to_s)
  end

  def autotest_files_dir
    File.join(autotest_path, TestRun::FILES_DIR)
  end

  def autotest_files
    files_dir = Pathname.new autotest_files_dir
    return [] unless Dir.exist? files_dir

    Dir.glob("#{files_dir}/**/*", File::FNM_DOTMATCH).filter_map do |f|
      unless %w[.. .].include?(File.basename(f))
        Pathname.new(f).relative_path_from(files_dir).to_s
      end
    end
  end

  def scanned_exams_path
    dir = Settings.file_storage.scanned_exams || File.join(Settings.file_storage.default_root_path, 'scanned_exams')
    Rails.root.join(File.join(dir, self.id.to_s))
  end

  # Retrieve current grader data.
  def current_grader_data
    ta_counts = self.criterion_ta_associations.group(:ta_id).count
    grader_data = self.groupings
                      .joins(tas: :user)
                      .group('user_name')
                      .count
    graders = self.course.tas.joins(:user)
                  .pluck(:user_name, :first_name, :last_name, 'roles.id',
                         'roles.hidden').map do |user_name, first_name, last_name, id, hidden|
      {
        user_name: user_name,
        first_name: first_name,
        last_name: last_name,
        groups: grader_data[user_name] || 0,
        _id: id,
        criteria: ta_counts[id] || 0,
        hidden: hidden
      }
    end

    group_data = self.groupings
                     .left_outer_joins(:group, tas: :user)
                     .pluck('groupings.id', 'groups.group_name', 'users.user_name', 'roles.hidden',
                            'groupings.criteria_coverage_count')
    groups = Hash.new { |h, k| h[k] = [] }
    group_data.each do |group_id, group_name, ta, hidden, count|
      groups[[group_id, group_name, count]]
      groups[[group_id, group_name, count]] << { grader: ta, hidden: hidden } unless ta.nil?
    end
    group_sections = self.groupings.left_outer_joins(:section).pluck('groupings.id', 'sections.id').to_h
    groups = groups.map do |k, v|
      {
        _id: k[0],
        group_name: k[1],
        criteria_coverage_count: k[2],
        section: group_sections[k[0]],
        graders: v
      }
    end

    criterion_data =
      self.criteria.left_outer_joins(tas: :user)
          .pluck('criteria.name', 'criteria.position',
                 'criteria.assigned_groups_count', 'users.user_name', 'roles.hidden')
    criteria = Hash.new { |h, k| h[k] = [] }
    criterion_data.sort_by { |c| c[3] || '' }.each do |name, pos, count, ta, hidden|
      criteria[[name, pos, count]]
      criteria[[name, pos, count]] << { grader: ta, hidden: hidden } unless ta.nil?
    end
    criteria = criteria.map do |k, v|
      {
        name: k[0],
        _id: k[1], # NOTE: _id is the *position* of the criterion
        coverage: k[2],
        graders: v
      }
    end

    result = {
      groups: groups,
      criteria: criteria,
      graders: graders,
      assign_graders_to_criteria: self.assign_graders_to_criteria,
      anonymize_groups: self.anonymize_groups,
      hide_unassigned_criteria: self.hide_unassigned_criteria,
      sections: assignment.course.sections.pluck(:id, :name).to_h
    }

    members_data = assignment.groupings.joins(student_memberships: { role: :user })
                             .pluck('groupings.id', 'users.user_name', 'memberships.membership_status', 'roles.hidden')

    grouped_data = members_data.group_by { |x| x[0] }
    grouped_data.each_value { |a| a.each { |b| b.delete_at(0) } }

    result[:groups].each do |group|
      group[:members] = grouped_data[group[:_id]] || []
    end

    result
  end

  # Retrieve data for submissions table.
  # Uses joins and pluck rather than includes to improve query speed.
  def current_submission_data(current_role)
    if current_role.instructor?
      groupings = self.groupings
    elsif current_role.ta?
      groupings = self.groupings.where(id: self.groupings.joins(:ta_memberships)
                                                         .where('memberships.role_id': current_role.id)
                                                         .select(:'groupings.id'))
    else
      return []
    end

    data = groupings
           .left_outer_joins(:group, :current_submission_used)
           .pluck('groupings.id',
                  'groups.group_name',
                  'submissions.revision_timestamp',
                  'submissions.is_empty',
                  'groupings.start_time')

    tag_data = groupings
               .joins(:tags)
               .pluck_to_hash('groupings.id', 'tags.name')
               .group_by { |h| h['groupings.id'] }

    if self.submission_rule.is_a? GracePeriodSubmissionRule
      deductions = groupings
                   .joins(:grace_period_deductions)
                   .group('groupings.id')
                   .maximum('grace_period_deductions.deduction')
    else
      deductions = {}
    end

    # All results for the currently-used submissions, including both remark and original results
    result_data = self.non_pr_results.joins(:grouping)
                      .order('results.created_at DESC')
                      .pluck_to_hash('groupings.id',
                                     'results.id',
                                     'results.marking_state',
                                     'results.released_to_students',
                                     'results.view_token',
                                     'results.view_token_expiry')
                      .group_by { |h| h['groupings.id'] }

    if current_role.ta? && anonymize_groups
      member_data = {}
      section_data = {}
    else
      member_data = groupings.joins(accepted_students: :user)
                             .pluck_to_hash('groupings.id', 'users.user_name', 'roles.hidden')
                             .group_by { |h| h['groupings.id'] }

      section_data = groupings.joins(inviter: :section)
                              .pluck('groupings.id', 'sections.name')
                              .to_h
    end

    if current_role.ta? && hide_unassigned_criteria
      assigned_criteria = current_role.criterion_ta_associations
                                      .where(assessment_id: self.id)
                                      .pluck(:criterion_id)
    else
      assigned_criteria = nil
    end

    visible_criteria = current_role.instructor? ? self.criteria : self.ta_criteria
    criteria = visible_criteria.reject do |crit|
      !assigned_criteria.nil? && assigned_criteria.exclude?(crit.id)
    end

    result_ids = result_data.values.flat_map { |arr| arr.pluck('results.id') }

    total_marks = Mark.where(criterion: criteria, result_id: result_ids)
                      .pluck(:result_id, :mark)
                      .group_by(&:first)
                      .transform_values { |arr| arr.filter_map(&:second).sum }

    # The sum is converted from a BigDecimal to a float so that when it is passed to the frontend it is not a string
    max_mark = Float(criteria.filter_map { |c| c.bonus ? nil : c.max_mark }.sum.round(2))
    extra_marks_hash = Result.get_total_extra_marks(result_ids, max_mark: max_mark)

    collection_dates = all_grouping_collection_dates

    data_collections = [tag_data, result_data, member_data, section_data, collection_dates]

    # This is the submission data that's actually returned
    data.map do |grouping_id, group_name, revision_timestamp, is_empty, start_time|
      tag_info, result_info, member_info, section_info, collection_date = data_collections.pluck(grouping_id)
      has_remark = result_info&.count&.> 1
      result_info = result_info&.first || {}

      base = {
        _id: grouping_id, # Needed for checkbox version of react-table
        max_mark: max_mark,
        group_name: current_role.ta? && anonymize_groups ? "#{Group.model_name.human} #{grouping_id}" : group_name,
        tags: (tag_info.nil? ? [] : tag_info.pluck('tags.name')),
        marking_state: marking_state(has_remark,
                                     result_info['results.marking_state'],
                                     result_info['results.released_to_students'],
                                     collection_date)
      }

      base[:start_time] = I18n.l(start_time) if self.is_timed && !start_time.nil?

      unless is_empty || revision_timestamp.nil?
        # TODO: for some reason, this is not automatically converted to our timezone by the query
        base[:submission_time] = I18n.l(revision_timestamp.in_time_zone)
      end

      if result_info['results.id'].present?
        extra_mark = extra_marks_hash[result_info['results.id']] || 0
        base[:result_id] = result_info['results.id']
        base[:final_grade] = [0, (total_marks[result_info['results.id']] || 0.0) + extra_mark].max
        if self.release_with_urls
          base[:result_view_token] = result_info['results.view_token']
          token_expiry = result_info['results.view_token_expiry']
          base[:result_view_token_expiry] = token_expiry.nil? ? nil : I18n.l(token_expiry.in_time_zone)
        end
      end

      base[:members] = member_info.nil? ? [] : member_info.pluck('users.user_name', 'roles.hidden')
      base[:section] = section_info unless section_info.nil?
      base[:grace_credits_used] = deductions[grouping_id] if self.submission_rule.is_a? GracePeriodSubmissionRule

      base
    end
  end

  def to_xml(options = {})
    attributes_hash = self.assignment_properties.attributes.merge(self.attributes).symbolize_keys
    attributes_hash.slice(*Api::AssignmentsController::DEFAULT_FIELDS).to_xml(options)
  end

  def to_json(options = {})
    self.assignment_properties.attributes.merge(self.attributes).symbolize_keys.to_json(options)
  end

  # Returns an assignment's relevant properties for uploading/downloading an assignment's configuration as a hash
  def assignment_properties_config
    # Data to avoid including
    exclude = %w[id created_at updated_at repository_folder has_peer_review]
    should_reject = ->(attr) { attr.end_with?('_id', '_created_at', '_updated_at') }
    # Helper lambda functions for filtering attributes
    filter_attr = ->(attributes) { attributes.except(*exclude).reject { |attr| should_reject.call(attr) } }
    filter_table = ->(data, model) do
      data.pluck_to_hash(*(model.column_names - exclude).reject { |attr| should_reject.call(attr) })
    end
    # Build properties
    properties = self.attributes.except(*exclude).reject { |attr| should_reject.call(attr) || attr == 'type' }
    properties['parent_assessment_short_identifier'] = self.parent_assignment.short_identifier if self.is_peer_review?
    properties['assignment_properties_attributes'] = filter_attr.call(self.assignment_properties.attributes)
    properties['assignment_files_attributes'] = filter_table.call(self.assignment_files, AssignmentFile)
    properties['submission_rule_attributes'] = filter_attr.call(self.submission_rule.attributes)
    properties['submission_rule_attributes']['periods_attributes'] = filter_table.call(self.submission_rule.periods,
                                                                                       Period)
    properties
  end

  # Writes this assignment's starter file settings to the file located at +settings_filepath+ located in the
  # +zip_file+. Also writes the starter files for this assignment in the same directory as +settings_filepath+.
  def starter_file_config_to_zip(zip_file, settings_filepath)
    default_starter_group = nil
    group_data = []
    directory_path = File.dirname(settings_filepath)
    self.starter_file_groups.each do |starter_file_group|
      group_name = ActiveStorage::Filename.new(starter_file_group.name).sanitized
      starter_file_group.write_starter_files_to_zip(zip_file, File.join(directory_path, group_name))
      if starter_file_group.id == self.default_starter_file_group_id
        default_starter_group = group_name
      end
      group_data << {
        directory_name: group_name,
        name: starter_file_group.name,
        use_rename: starter_file_group.use_rename,
        entry_rename: starter_file_group.entry_rename
      }
    end
    starter_file_settings = {
      default_starter_file_group: default_starter_group,
      starter_file_groups: group_data
    }.to_yaml
    zip_file.get_output_stream(settings_filepath) { |f| f.write starter_file_settings }
  end

  # zip all files in the folder at +self.autotest_files_dir+ and return the
  # path to the zip file
  def zip_automated_test_files(user)
    zip_name = "#{self.short_identifier}-testfiles-#{user.user_name}"
    zip_path = File.join('tmp', zip_name + '.zip')
    FileUtils.rm_rf zip_path
    Zip::File.open(zip_path, create: true) do |zip_file|
      self.add_test_files_to_zip(zip_file, '')
    end
    zip_path
  end

  # Writes all of this assignment's automated test files to the +zip_dir+ in +zip_file+. Also writes
  # the tester settings specified in this assignment's properties to the json file at
  # +specs_file_path+ in the +zip_file+.
  def automated_test_config_to_zip(zip_file, zip_dir, specs_file_path)
    self.add_test_files_to_zip(zip_file, zip_dir)
    test_specs = autotest_settings_for(self)
    test_specs['testers']&.each do |tester_info|
      tester_info['test_data']&.each do |test_info|
        test_info['extra_info']&.delete('test_group_id')
      end
    end
    zip_file.get_output_stream(specs_file_path) do |f|
      f.write(test_specs.to_json)
    end
  end

  private

  def add_test_files_to_zip(zip_file, zip_base_dir)
    files_dir = Pathname.new self.autotest_files_dir
    self.autotest_files.map do |file|
      path = zip_base_dir.empty? ? file : File.join(zip_base_dir, file)
      abs_path = files_dir.join(file)
      if abs_path.directory?
        zip_file.mkdir(path)
      else
        zip_file.get_output_stream(path) { |f| f.print File.read(abs_path.to_s, mode: 'rb') }
      end
    end
  end

  def create_autotest_dirs
    FileUtils.mkdir_p self.autotest_path
    FileUtils.mkdir_p self.autotest_files_dir
  end

  # Returns the marking state used in the submission and course summary tables
  # for the result(s) for single submission.
  #
  # +has_remark+ is a boolean indicating whether a remark request exists for this submission
  # +result_marking_state+ is one of Result::MARKING_STATES or nil if there are no results for this submission
  # +released_to_students+ is a boolean indicating whether a result has been released to students
  # +collection_date+ is a Time object indicating when the submission was collected
  def marking_state(has_remark, result_marking_state, released_to_students, collection_date)
    if result_marking_state.present?
      return 'remark' if result_marking_state == Result::MARKING_STATES[:incomplete] && has_remark
      return 'released' if released_to_students

      return result_marking_state
    end
    return 'not_collected' if collection_date < Time.current

    'before_due_date'
  end

  def reset_collection_time
    submission_rule.reset_collection_time
  end

  def update_assigned_tokens
    old, new = assignment_properties.saved_change_to_tokens_per_period || [0, 0]
    difference = new - old
    unless difference.zero?
      max_tokens = assignment_properties.tokens_per_period
      groupings.each do |g|
        g.test_tokens = (g.test_tokens + difference).clamp(0, max_tokens)
        g.save
      end
    end
  end

  def create_associations
    return unless self.new_record?
    self.assignment_properties ||= AssignmentProperties.new
    self.submission_rule ||= NoLateSubmissionRule.new
  end

  # Update the repository permissions file if one of the following attributes was changed after a save:
  # - vcs_submit
  # - is_hidden or section-specific is_hidden
  # - anonymize_groups
  def update_repo_permissions
    return unless
      saved_change_to_vcs_submit? ||
        saved_change_to_anonymize_groups? ||
        visibility_changed?

    Repository.get_class.update_permissions
  end

  # Update parent assignment of a peer review to ensure that it is marked as having a peer review
  def update_parent_assignment
    parent_assignment.update(has_peer_review: true)
  end

  # Update list of required files in student repositories. Used for git hooks to prevent submitting
  # non-required files. Updated when one of the following attributes was changed after a save:
  # - only_required_files
  # - is_hidden or section-specific is_hidden
  # - any assignment files
  def update_repo_required_files
    return unless Settings.repository.type == 'git'
    return unless
      saved_change_to_only_required_files? ||
        assignment_files.any?(&:saved_changes?) ||
        visibility_changed? ||
        @prev_assignment_file_ids != self.reload.assignment_files.ids

    UpdateRepoRequiredFilesJob.perform_later(self.id)
  end

  # Returns whether the visibility for this assignment changed after a save.
  def visibility_changed?
    saved_change_to_is_hidden? ||
      saved_change_to_visible_on? ||
      saved_change_to_visible_until? ||
      assessment_section_properties.any?(&:is_hidden_previously_changed?) ||
      assessment_section_properties.any?(&:visible_on_previously_changed?) ||
      assessment_section_properties.any?(&:visible_until_previously_changed?) ||
      @prev_assessment_section_property_ids != self.reload.assessment_section_properties.ids
  end
end
