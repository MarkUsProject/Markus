require 'csv_invalid_line_error'

class Assignment < ActiveRecord::Base
  include RepositoryHelper

  MIN_PEER_REVIEWS_PER_GROUP = 1

  has_many :rubric_criteria,
           -> { order(:position) },
           class_name: 'RubricCriterion',
		   dependent: :destroy

  has_many :flexible_criteria,
           -> { order(:position) },
           class_name: 'FlexibleCriterion',
       dependent: :destroy

  has_many :checkbox_criteria,
           -> { order(:position) },
           class_name: 'CheckboxCriterion',
       dependent: :destroy

  has_many :test_support_files, dependent: :destroy
  accepts_nested_attributes_for :test_support_files, allow_destroy: true
  has_many :test_scripts, dependent: :destroy
  accepts_nested_attributes_for :test_scripts, allow_destroy: true


  has_many :annotation_categories,
           -> { order(:position) },
           class_name: 'AnnotationCategory',
           dependent: :destroy

  has_many :criterion_ta_associations,
		   dependent: :destroy

  has_many :assignment_files,
		   dependent: :destroy
  accepts_nested_attributes_for :assignment_files, allow_destroy: true
  validates_associated :assignment_files

  has_one :assignment_stat, dependent: :destroy
  accepts_nested_attributes_for :assignment_stat, allow_destroy: true
  validates_associated :assignment_stat
  # Because of app/views/main/_grade_distribution_graph.html.erb:25
  validates_presence_of :assignment_stat

  # Assignments can now refer to themselves, where this is null if there
  # is no parent (the same holds for the child peer reviews)
  belongs_to :parent_assignment, class_name: 'Assignment', inverse_of: :pr_assignment
  has_one :pr_assignment, class_name: 'Assignment', foreign_key: :parent_assignment_id, inverse_of: :parent_assignment
  has_many :peer_reviews, through: :groupings
  has_many :pr_peer_reviews, through: :parent_assignment, source: :peer_reviews

  has_many :annotation_categories,
           -> { order(:position) },
           class_name: 'AnnotationCategory',
		   dependent: :destroy

  has_many :groupings

  has_many :ta_memberships, through: :groupings
  has_many :student_memberships, through: :groupings
  has_many :tokens, through: :groupings

  has_many :submissions, through: :groupings
  has_many :groups, through: :groupings

  has_many :notes, as: :noteable, dependent: :destroy

  has_many :section_due_dates
  accepts_nested_attributes_for :section_due_dates


  validates_uniqueness_of :short_identifier, case_sensitive: true
  validates_numericality_of :group_min, only_integer: true, greater_than: 0
  validates_numericality_of :group_max, only_integer: true, greater_than: 0

  has_one :submission_rule, dependent: :destroy, inverse_of: :assignment
  accepts_nested_attributes_for :submission_rule, allow_destroy: true
  validates_associated :submission_rule
  validates_presence_of :submission_rule

  validates_presence_of :short_identifier
  validates_presence_of :description
  validates_presence_of :repository_folder
  validates_presence_of :due_date
  validates_presence_of :group_min
  validates_presence_of :group_max
  validates_presence_of :notes_count
  validates_presence_of :assignment_stat
  # "validates_presence_of" for boolean values.
  validates_inclusion_of :allow_web_submits, in: [true, false]
  validates_inclusion_of :vcs_submit, in: [true, false]
  validates_inclusion_of :display_grader_names_to_students, in: [true, false]
  validates_inclusion_of :is_hidden, in: [true, false]
  validates_inclusion_of :has_peer_review, in: [true, false]
  validates_inclusion_of :assign_graders_to_criteria, in: [true, false]

  validates_inclusion_of :enable_test, in: [true, false]
  validates_inclusion_of :enable_student_tests, in: [true, false], if: :enable_test
  validates_inclusion_of :unlimited_tokens, in: [true, false], if: :enable_student_tests
  validates_presence_of :token_start_date, if: :enable_student_tests
  with_options if: ->{ :enable_student_tests && !:unlimited_tokens } do |assignment|
    assignment.validates :tokens_per_period,
                         presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 0 }
    assignment.validates :token_period,
                         presence: true,
                         numericality: { greater_than: 0 }
  end

  validate :minimum_number_of_groups

  after_create :build_repository

  before_save :reset_collection_time

  # Call custom validator in order to validate the :due_date attribute
  # date: true maps to DateValidator (custom_name: true maps to CustomNameValidator)
  # Look in lib/validators/* for more info
  validates :due_date, date: true
  after_save :update_assigned_tokens
  after_save :create_peer_review_assignment_if_not_exist

  # Set the default order of assignments: in ascending order of due_date
  default_scope { order('due_date ASC') }

  def minimum_number_of_groups
    if (group_max && group_min) && group_max < group_min
      errors.add(:group_max, 'must be greater than the minimum number of groups')
      false
    end
  end

  # Are we past all the due dates for this assignment?
  def past_all_due_dates?
    # If no section due dates /!\ do not check empty? it could be wrong
    unless self.section_due_dates_type
      return !due_date.nil? && Time.zone.now > due_date
    end

    # If section due dates
    self.section_due_dates.each do |d|
      if !d.due_date.nil? && Time.zone.now > d.due_date
        return true
      end
    end
    false
  end

  # Return an array with names of sections past
  def section_names_past_due_date
    sections_past = []

    unless self.section_due_dates_type
      if !due_date.nil? && Time.zone.now > due_date
        return sections_past << 'Due Date'
      end
    end

    self.section_due_dates.each do |d|
      if !d.due_date.nil? && Time.zone.now > d.due_date
        sections_past << d.section.name
      end
    end

    sections_past
  end

  # Whether or not this grouping is past its due date for this assignment.
  def grouping_past_due_date?(grouping)
    if section_due_dates_type && grouping &&
      grouping.inviter.section.present?

      section_due_date =
        SectionDueDate.due_date_for(grouping.inviter.section, self)
      !section_due_date.nil? && Time.zone.now > section_due_date
    else
      past_all_due_dates?
    end
  end

  def section_due_date(section)
    unless section_due_dates_type && section
      return due_date
    end

    SectionDueDate.due_date_for(section, self)
  end

  # Calculate the latest due date among all sections for the assignment.
  def latest_due_date
    return due_date unless section_due_dates_type
    due_dates = section_due_dates.map(&:due_date) << due_date
    due_dates.compact.max
  end

  def past_collection_date?(section=nil)
    Time.zone.now > submission_rule.calculate_collection_time(section)
  end

  def past_all_collection_dates?
    Time.zone.now > latest_due_date
  end

  def past_remark_due_date?
    !remark_due_date.nil? && Time.zone.now > remark_due_date
  end

  # Return true if this is a group assignment; false otherwise
  def group_assignment?
    invalid_override || group_max > 1
  end

  # Returns the group by the user for this assignment. If pending=true,
  # it will return the group that the user has a pending invitation to.
  # Returns nil if user does not have a group for this assignment, or if it is
  # not a group assignment
  def group_by(uid, pending=false)
    return unless group_assignment?

    # condition = "memberships.user_id = ?"
    # condition += " and memberships.status != 'rejected'"
    # add non-pending status clause to condition
    # condition += " and memberships.status != 'pending'" unless pending
    # groupings.first(include: :memberships, conditions: [condition, uid]) #FIXME: needs schema update

    #FIXME: needs to be rewritten using a proper query...
    User.find(uid.id).accepted_grouping_for(id)
  end

  def display_for_note
    short_identifier
  end

  # Returns the maximum possible mark for a particular assignment
  def max_mark(user_visibility = :ta)
    get_criteria(user_visibility).map(&:max_mark).sum.round(2)
  end

  # calculates summary statistics of released results for this assignment
  def update_results_stats
    marks = Result.student_marks_by_assignment(id)
    # No marks released for this assignment.
    return false if marks.empty?

    self.results_fails = marks.count { |mark| mark < max_mark / 2.0 }
    self.results_zeros = marks.count(&:zero?)

    # Avoid division by 0.
    self.results_average, self.results_median =
      if max_mark.zero?
        [0, 0]
      else
        # Calculates average and median in percentage.
        [average(marks), median(marks)].map do |stat|
          (stat * 100 / max_mark).round(2)
        end
      end
    self.save
  end

  def average(marks)
    marks.empty? ? 0 : marks.reduce(:+) / marks.size.to_f
  end

  def median(marks)
    count = marks.size
    return 0 if count.zero?

    if count.even?
      average([marks[count/2 - 1], marks[count/2]])
    else
      marks[count/2]
    end
  end

  def self.get_current_assignment
    # start showing (or "featuring") the assignment 3 days before it's due
    # query uses Date.today + 4 because results from db seems to be off by 1
    current_assignment = Assignment.where('due_date <= ?', Date.today + 4)
                                   .reorder('due_date DESC').first

    if current_assignment.nil?
      current_assignment = Assignment.reorder('due_date ASC').first
    end

    current_assignment
  end

  def update_remark_request_count
    outstanding_count = 0
    groupings.each do |grouping|
      submission = grouping.current_submission_used
      if !submission.nil? && submission.has_remark?
        if submission.remark_result.marking_state ==
            Result::MARKING_STATES[:incomplete]
          outstanding_count += 1
        end
      end
    end
    self.outstanding_remark_request_count = outstanding_count
    self.save
  end

  def total_instructor_test_script_marks
    return test_scripts.where('run_by_instructors' => true).sum('max_marks')
  end

  #total marks for scripts that are run on student request
  def total_student_test_script_marks
    return test_scripts.where('run_by_students' => true).sum('max_marks')
  end

  def add_group(new_group_name=nil)
    if group_name_autogenerated
      group = Group.new
      group.save(validate: false)
      group.group_name = group.get_autogenerated_group_name
      group.save
    else
      return if new_group_name.nil?
      if group = Group.where(group_name: new_group_name).first
        unless groupings.where(group_id: group.id).first.nil?
          raise "Group #{new_group_name} already exists"
        end
      else
        group = Group.create(group_name: new_group_name)
      end
    end
    group.set_repo_permissions
    Grouping.create(group: group, assignment: self)
  end

  # Clones the Groupings from the assignment with id assignment_id
  # into self.  Destroys any previously existing Groupings associated
  # with this Assignment
  def clone_groupings_from(assignment_id)
    original_assignment = Assignment.find(assignment_id)
    self.transaction do
      self.group_min = original_assignment.group_min
      self.group_max = original_assignment.group_max
      self.student_form_groups = original_assignment.student_form_groups
      self.group_name_autogenerated = original_assignment.group_name_autogenerated
      self.group_name_displayed = original_assignment.group_name_displayed
      self.groupings.destroy_all
      self.save
      self.reload
      original_assignment.groupings.each do |g|
        unhidden_student_memberships = g.accepted_student_memberships.select do |m|
          !m.user.hidden
        end
        unhidden_ta_memberships = g.ta_memberships.select do |m|
          !m.user.hidden
        end
        #create the memberships for any user that is not hidden
        unless unhidden_student_memberships.empty?
          #create the groupings
          grouping = Grouping.new
          grouping.group_id = g.group_id
          grouping.assignment_id = self.id
          grouping.admin_approved = g.admin_approved
          raise 'Could not save grouping' if !grouping.save
          all_memberships = unhidden_student_memberships + unhidden_ta_memberships
          all_memberships.each do |m|
            membership = Membership.new
            membership.user_id = m.user_id
            membership.type = m.type
            membership.membership_status = m.membership_status
            raise 'Could not save membership' if !(grouping.memberships << membership)
          end
          # Ensure all student members have permissions on their group repositories
          grouping.update_repository_permissions
        end
      end
    end
  end

  # Add a group and corresponding grouping as provided in
  # the passed in Array.
  # Format: [ groupname, repo_name, member, member, etc ]
  # The groupname, repo_name must not pre exist, each member should exist and
  # not belong to a different grouping for the same assignment.
  # If these requirements are not satisfied, the group and the grouping is
  # not created.
  def add_csv_group(row)
    return if row.length.zero?

    begin
      row.map! { |item| item.strip }
    rescue NoMethodError
      raise CSVInvalidLineError
    end

    group = Group.where(group_name: row.first).first

    unless group.nil?
      if group.repo_name != row[1]
        # CASE: Group already exists but the repo name is different
        duplicate_group_error = I18n.t('csv.group_with_different_repo',
                                       group_name: row[0])
        raise CSVInvalidLineError, duplicate_group_error
      else
        any_grouping = Grouping.find_by group_id: group.id
        if any_grouping.nil?
          # CASE: Group exists with same repo name but has no grouping
          #       associated with it for any assignment
          # Use existing group and create a new grouping between the existing
          # group and the given students and return without error
          add_new_grouping_for_group(row, group)
          return
        else
          grouping_for_current_assignment = group.grouping_for_assignment(id)
          if grouping_for_current_assignment.nil?
            if same_membership_as_csv_row?(row, any_grouping)
              # CASE: Group already exists with the same repo name and has a
              #     grouping for another assignment with the same membership
              # Use existing group and create a new grouping between the
              # existing  group and the given students and return without error
              add_new_grouping_for_group(row, group)
              return
            else
              # CASE: Group already exists with the same repo name and has
              #     a grouping for another assignment BUT with different
              #     membership
              # The existing groupings and the current group is not compatible
              # Return an error.
              duplicate_group_error = I18n.t(
                'csv.group_with_different_membership_different_assignment',
                group_name: row[0])
              raise CSVInvalidLineError, duplicate_group_error
            end
          else
            if same_membership_as_csv_row?(row,
                                           grouping_for_current_assignment)
              # CASE: Group already exists with the same repo name and also has
              #     a grouping for the current assignment with the same
              #     membership
              # No new group or grouping created. Since the exact group given by
              # the csv file already exists treat this as a successful case
              # and don't return an error
              return
            else
              # CASE: Group already exists with the same repo name and has a
              #     grouping for the current assignment BUT the membership is
              #     different.
              # Return error since the membership is different
              duplicate_group_error = I18n.t(
                'csv.group_with_different_membership_current_assignment',
                group_name: row[0])
              raise CSVInvalidLineError, duplicate_group_error
            end
          end
        end
      end

    end

    # If any of the given members do not exist or is part of another group,
    # an error is returned without creating a group
    unless membership_unique?(row)
      if !errors[:groupings].blank?
        # groupings error set if a member is already in different group
        membership_error = I18n.t('csv.memberships_not_unique',
                                  group_name: row[0],
                                  student_user_name: errors.get(:groupings)
                                                         .first)
        errors.delete(:groupings)
      else
        # student_membership error set if a member does not exist
        membership_error = I18n.t(
          'csv.member_does_not_exist',
          group_name: row[0],
          student_user_name: errors.get(:student_memberships).first)
        errors.delete(:student_memberships)
      end
      return membership_error
    end

    # If this assignment is an individual assignment, then the repostiory
    # name is set to be the student's user name. If this assignment is a
    # group assignment then the repository name is taken from the csv file
    if is_candidate_for_setting_custom_repo_name?(row)
      repo_name = row[2]
    else
      repo_name = row[1]
    end

    # If a repository already exists with the same repo name as the one given
    #  in the csv file, error is returned and the group is not created
    begin
      if repository_already_exists?(repo_name)
        repository_error = I18n.t('csv.repository_already_exists',
                                  group_name: row[0],
                                  repo_path: errors.get(:repo_name).last)
        errors.delete(:repo_name)
        return repository_error
      end
    rescue TypeError
      raise CSV::MalformedCSVError
    end

    # At this point we can be sure that the group_name, memberships and
    # the repo_name does not already exist. So we create the new group.
    group = Group.new
    group.group_name = row[0]
    group.repo_name = repo_name

    # Note: after_create hook build_repository might raise
    # Repository::RepositoryCollision. If it does, it adds the colliding
    # repo_name to errors.on_base. This is how we can detect repo
    # collisions here. Unfortunately, we can't raise an exception
    # here, because we still want the grouping to be created. This really
    # shouldn't happen anyway, because the lookup earlier should prevent
    # repo collisions e.g. when uploading the same CSV file twice.
    group.save
    unless group.errors[:base].blank?
      collision_error = I18n.t('csv.repo_collision_warning',
                               repo_name: group.errors.on_base,
                               group_name: row[0])
    end

    add_new_grouping_for_group(row, group)
    collision_error
  end

  def grouped_students
    student_memberships.map(&:user)
  end

  def ungrouped_students
    Student.where(hidden: false) - grouped_students
  end

  def valid_groupings
    groupings.includes(student_memberships: :user).select do |grouping|
      grouping.admin_approved ||
      grouping.student_memberships.count >= group_min
    end
  end

  def invalid_groupings
    groupings - valid_groupings
  end

  def assigned_groupings
    groupings.joins(:ta_memberships).includes(ta_memberships: :user).uniq
  end

  def unassigned_groupings
    groupings - assigned_groupings
  end

  # Get a list of subversion client commands to be used for scripting
  def get_svn_checkout_commands
    svn_commands = [] # the commands to be exported

    self.groupings.each do |grouping|
      submission = grouping.current_submission_used
      if submission
        svn_commands.push(
          "svn checkout -r #{submission.revision_number} " +
          "#{grouping.group.repository_external_access_url}/" +
          "#{repository_folder} \"#{grouping.group.group_name}\"")
      end
    end
    svn_commands
  end

  # Get a list of group_name, repo-url pairs
  def get_svn_repo_list
    CSV.generate do |csv|
      self.groupings.each do |grouping|
        group = grouping.group
        csv << [group.group_name,group.repository_external_access_url]
      end
    end
  end

  # Get a detailed CSV report of criteria based marks
  # (includes each criterion, with it's out-of value) for this assignment.
  # Produces CSV rows such as the following:
  #   student_name,95.22222,3,4,2,5,5,4,0/2
  # Criterion values should be read in pairs. I.e. 2,3 means 2 out-of 3.
  # Last column are grace-credits.
  def get_detailed_csv_report
    out_of = max_mark
    students = Student.all
    MarkusCSV.generate(students) do |student|
      result = [student.user_name]
      grouping = student.accepted_grouping_for(self.id)
      if grouping.nil? || !grouping.has_submission?
        # No grouping/no submission
        # total percentage, total_grade
        result.concat(['','0'])
        # mark, max_mark
        result.concat(Array.new(criteria_count, '').
          zip(get_criteria.map(&:max_mark)).flatten)
        # extra-mark, extra-percentage
        result.concat(['',''])
      else
        # Fill in actual values, since we have a grouping
        # and a submission.
        submission = grouping.current_submission_used
        result.concat([submission.get_latest_result.total_mark / out_of * 100,
                       submission.get_latest_result.total_mark])
        get_marks_list(submission).each do |mark|
          result.concat(mark)
        end
        result.concat([submission.get_latest_result.get_total_extra_points,
                       submission.get_latest_result.get_total_extra_percentage])
      end
      # push grace credits info
      grace_credits_data = student.remaining_grace_credits.to_s + '/' + student.grace_credits.to_s
      result.push(grace_credits_data)
      result
    end
  end

  # Returns an array of [mark, max_mark].
  def get_marks_list(submission)
    get_criteria.map do |criterion|
      mark = submission.get_latest_result.marks.find_by(markable: criterion)
      [(mark.nil? || mark.mark.nil?) ? '' : mark.mark,
       criterion.max_mark]
    end
  end

  def replace_submission_rule(new_submission_rule)
    if self.submission_rule.nil?
      self.submission_rule = new_submission_rule
      self.save
    else
      self.submission_rule.destroy
      self.submission_rule = new_submission_rule
      self.save
    end
  end

  def next_criterion_position
    # We're using count here because this fires off a DB query, thus
    # grabbing the most up-to-date count of the criteria.
    get_criteria.count > 0 ? get_criteria.last.position + 1 : 1
  end

  # Returns a filtered list of criteria.
  def get_criteria(user_visibility = :all, type = :all, options = {})
    include_opt = options[:includes]
    if user_visibility == :all
      get_all_criteria(type, include_opt)
    elsif user_visibility == :ta
      get_ta_visible_criteria(type, include_opt)
    elsif user_visibility == :peer
      get_peer_visible_criteria(type, include_opt)
    end
  end

  def get_all_criteria(type, include_opt)
    if type == :all
      all_criteria = rubric_criteria.includes(include_opt) +
                     flexible_criteria.includes(include_opt) +
                     checkbox_criteria.includes(include_opt)
      all_criteria.sort_by(&:position)
    elsif type == :rubric
      rubric_criteria.includes(include_opt).order(:position)
    elsif type == :flexible
      flexible_criteria.includes(include_opt).order(:position)
    elsif type == :checkbox
      checkbox_criteria.includes(include_opt).order(:position)
    end
  end

  def get_ta_visible_criteria(type, include_opt)
    get_all_criteria(type, include_opt).select(&:ta_visible)
  end

  def get_peer_visible_criteria(type, include_opt)
    get_all_criteria(type, include_opt).select(&:peer_visible)
  end

  def criteria_count
    get_criteria.size
  end

  # Returns an array with the number of groupings who scored between
  # certain percentage ranges [0-5%, 6-10%, ...]
  # intervals defaults to 20
  def grade_distribution_as_percentage(intervals=20)
    distribution = Array.new(intervals, 0)
    out_of = max_mark

    if out_of == 0
      return distribution
    end

    steps = 100 / intervals # number of percentage steps in each interval
    groupings = self.groupings.includes([{current_submission_used: :results}])

    groupings.each do |grouping|
      submission = grouping.current_submission_used
      if submission && submission.has_result?
        result = submission.get_latest_completed_result
        unless result.nil?
          percentage = (result.total_mark / out_of * 100).ceil
          if percentage == 0
            distribution[0] += 1
          elsif percentage >= 100
            distribution[intervals - 1] += 1
          elsif (percentage % steps) == 0
            distribution[percentage / steps - 1] += 1
          else
            distribution[percentage / steps] += 1
          end
        end
      end
    end # end of groupings loop

    distribution
  end

  # Returns all the TAs associated with the assignment
  def tas
    Ta.find(ta_memberships.map(&:user_id))
  end

  # Returns all the submissions that have been graded (completed)
  def graded_submission_results
    results = []
    groupings.each do |grouping|
      if grouping.marking_completed?
        submission = grouping.current_submission_used
        results.push(submission.get_latest_result) unless submission.nil?
      end
    end
    results
  end

  def groups_submitted
    groupings.select(&:has_submission?)
  end

  def get_num_assigned(ta_id = nil)
    if ta_id.nil?
      groupings.size
    else
      ta_memberships.where(user_id: ta_id).size
    end
  end

  def get_num_marked(ta_id = nil)
    if ta_id.nil?
      groupings.count(marking_completed: true)
    else
      n = 0
      ta_memberships.includes(grouping: [{current_submission_used: [:submitted_remark, :results]}]).where(user_id: ta_id).find_each do |x|
        x.grouping.marking_completed? && n += 1
      end
      n
    end
  end

  def get_num_annotations(ta_id = nil)
    if ta_id.nil?
      num_annotations_all
    else
      n = 0
      ta_memberships.where(user_id: ta_id).find_each do |x|
        x.grouping.marking_completed? &&
          n += x.grouping.current_submission_used.annotations.size
      end
      n
    end
  end

  def num_annotations_all
    groupings = Grouping.arel_table
    submissions = Submission.arel_table
    subs = Submission.joins(:grouping)
                     .where(groupings[:assignment_id].eq(id)
                     .and(submissions[:submission_version_used].eq(true)))

    res = Result.submitted_remarks_and_all_non_remarks
                .where(submission_id: subs.pluck(:id))
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

  # Assign graders to a criterion for this assignment.
  # Raise a CSVInvalidLineError if the criterion or a grader doesn't exist.
  def add_graders_to_criterion(criterion_name, graders)
    criterion = get_criteria.find{ |crit| crit.name == criterion_name }

    if criterion.nil?
      raise CSVInvalidLineError
    end

    unless graders.all? { |g| Ta.exists?(user_name: g) }
      raise CSVInvalidLineError
    end

    criterion.add_tas_by_user_name_array(graders)
  end

  # Returns the groupings of this assignment associated with the given section
  def section_groupings(section)
    groupings.select do |grouping|
      grouping.inviter.present? &&
      grouping.inviter.has_section? &&
      grouping.inviter.section.id == section.id
    end
  end

  def has_a_collected_submission?
    submissions.where(submission_version_used: true).count > 0
  end
  # Returns the groupings of this assignment that have no associated section
  def sectionless_groupings
    groupings.select do |grouping|
      grouping.inviter.present? &&
          !grouping.inviter.has_section?
    end
  end

  # TODO: This is currently disabled until starter code is automatically added
  # to groups.
  def can_upload_starter_code?
    #groups.size == 0
    false
  end

  # Returns true if this is a peer review, meaning it has a parent assignment,
  # false otherwise.
  def is_peer_review?
    not parent_assignment_id.nil?
  end

  # Returns true if this is a parent assignment that has a child peer review
  # assignment.
  def has_peer_review_assignment?
    not pr_assignment.nil?
  end

  def create_peer_review_assignment_if_not_exist
    if has_peer_review and Assignment.where(parent_assignment_id: id).empty?
      peerreview_assignment = Assignment.new
      peerreview_assignment.parent_assignment = self
      peerreview_assignment.submission_rule = NoLateSubmissionRule.new
      peerreview_assignment.assignment_stat = AssignmentStat.new
      peerreview_assignment.token_period = 1
      peerreview_assignment.unlimited_tokens = false
      peerreview_assignment.short_identifier = short_identifier + '_pr'
      peerreview_assignment.description = description
      peerreview_assignment.repository_folder = repository_folder
      peerreview_assignment.due_date = due_date
      peerreview_assignment.is_hidden = true

      # We do not want to have the database in an inconsistent state, so we
      # need to have the database rollback the 'has_peer_review' column to
      # be false
      if not peerreview_assignment.save
        raise ActiveRecord::Rollback
      end
    end
  end

  ### REPO ###

  def repository_name
    "#{short_identifier}_starter_code"
  end

  def build_repository
    # create repositories if and only if we are admin
    return true unless MarkusConfigurator.markus_config_repository_admin?
    # only create if we can add starter code
    return true unless can_upload_starter_code?
    begin
      Repository.get_class(MarkusConfigurator.markus_config_repository_type)
                .create(File.join(MarkusConfigurator.markus_config_repository_storage,
                                  repository_name))
    rescue Repository::RepositoryCollision => e
      # log the collision
      errors.add(:base, self.repo_name)
      m_logger = MarkusLogger.instance
      m_logger.log("Creating repository '#{repository_name}' caused repository collision. " +
                     "Error message: '#{e.message}'",
                   MarkusLogger::ERROR)
    end
    true
  end
  
  # Return a repository object, if possible
  def repo
    repo_loc = File.join(MarkusConfigurator.markus_config_repository_storage, repository_name)
    if Repository.get_class(MarkusConfigurator.markus_config_repository_type).repository_exists?(repo_loc)
      Repository.get_class(MarkusConfigurator.markus_config_repository_type).open(repo_loc)
    else
      raise 'Repository not found and MarkUs not in authoritative mode!' # repository not found, and we are not repo-admin
    end
  end

  #Yields a repository object, if possible, and closes it after it is finished
  def access_repo
    yield repo
    repo.close()
  end

  ### /REPO ###

  private

  # Returns true if we are safe to set the repository name
  # to a non-autogenerated value. Called by add_csv_group.
  def is_candidate_for_setting_custom_repo_name?(row)
    # Repository name can be customized if
    #  - this assignment is set up to allow external submits only
    #  - group_max = 1
    #  - there's only one student member in this row of the csv and
    #  - the group name is equal to the only group member
    if MarkusConfigurator.markus_config_repository_admin? &&
       self.allow_web_submits == false &&
       row.length == 3 && self.group_max == 1 &&
       !row[2].blank? && row[0] == row[2]
      true
    else
      false
    end
  end

  def reset_collection_time
    submission_rule.reset_collection_time
  end

  def update_assigned_tokens
    self.tokens.each do |t|
      t.update_tokens(tokens_per_period_was, tokens_per_period)
    end
  end

  def add_new_grouping_for_group(row, group)
    # Create a new Grouping for this assignment and the newly
    # crafted group
    grouping = Grouping.new(assignment: self, group: group)
    grouping.save

    # Form groups
    start_index_group_members = 2
    (start_index_group_members..(row.length - 1)).each do |i|
      student = Student.find_by user_name: row[i]
      if student
        if grouping.student_membership_number == 0
          # Add first valid member as inviter to group.
          grouping.group_id = group.id
          grouping.save # grouping has to be saved, before we can add members

          # We could call grouping.add_member, but it updates repo permissions
          # For performance reasons in the csv upload we will just create the
          # member here, and do the permissions update as a bulk operation.
          member = StudentMembership.new(
            user: student,
            membership_status: StudentMembership::STATUSES[:inviter],
            grouping: grouping)
          member.save
        else
          member = StudentMembership.new(
            user: student,
            membership_status: StudentMembership::STATUSES[:accepted],
            grouping: grouping)
          member.save
        end
      end
    end
  end

  #
  # Return true if for each membership given, a corresponding student exists
  # and if they are not part of a different grouping for the same assignment
  #
  def membership_unique?(row)
    start_index_group_members = 2 # index where student names start in the row
    (start_index_group_members..(row.length - 1)).each do |i|
      student = Student.find_by user_name: row[i]
      if student
        unless student.accepted_grouping_for(id).nil?
          errors.add(:groupings, student.user_name)
          return false
        end
      else
        errors.add(:student_memberships, row[i])
        return false
      end
    end
    true
  end

  # Return true if the given membership in the csv row is the exact same as the
  # membership of the given existing_grouping.
  def same_membership_as_csv_row?(row, existing_grouping)
    start_index_group_members = 2 # index where student names start in the row
    # check if all the members given in the csv file exists and belongs to the
    # given grouping
    (start_index_group_members..(row.length - 1)).each do |i|
      student = Student.find_by user_name: row[i]
      if student
        grouping = student
            .accepted_grouping_for(existing_grouping.assignment.id)
        if grouping.nil?
          # Student doesn't belong to a grouping for the given assignment
          # ==> membership cannot be the same
          return false
        elsif grouping.id != existing_grouping.id
          # Student belongs to a different grouping for the given assignment
          # ==> membership is different
          return false
        end
      else
        # Student doesn't exist in the database
        # # ==> membership cannot be the same
        return false
      end

      num_students_in_csv_row = row.length - start_index_group_members
      num_students_in_existing_grouping = grouping.accepted_students.length

      if num_students_in_csv_row != num_students_in_existing_grouping
        # All students given in the csv row belongs to the existing grouping
        # but the existing group contains more students than the ones given in
        # the csv row
        # ==> membership is different
        return false
      else
        # All students given in the csv row belongs to the existing grouping
        # and the grouping contains the same number of students as the one
        # in the csv row
        # ==> membership is the exact same
        return true
      end
    end
  end
end
