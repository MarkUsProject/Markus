require 'csv_invalid_line_error'

class Assignment < ActiveRecord::Base
  include RepositoryHelper
  MARKING_SCHEME_TYPE = {
    flexible: 'flexible',
    rubric: 'rubric'
  }

  has_many :rubric_criteria,
           -> { order(:position) },
           class_name: 'RubricCriterion',
		   dependent: :destroy

  has_many :flexible_criteria,
           -> { order(:position) },
           class_name: 'FlexibleCriterion',
		   dependent: :destroy

  has_many :criterion_ta_associations,
		   dependent: :destroy

  has_many :assignment_files,
		   dependent: :destroy
  accepts_nested_attributes_for :assignment_files, allow_destroy: true
  validates_associated :assignment_files

  has_many :test_files, dependent: :destroy
  accepts_nested_attributes_for :test_files, allow_destroy: true

  has_one :assignment_stat, dependent: :destroy
  accepts_nested_attributes_for :assignment_stat, allow_destroy: true
  validates_associated :assignment_stat
  # Because of app/views/main/_grade_distribution_graph.html.erb:25
  validates_presence_of :assignment_stat

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
  validates_numericality_of :tokens_per_day, only_integer: true, greater_than_or_equal_to: 0

  has_one :submission_rule, dependent: :destroy, inverse_of: :assignment
  accepts_nested_attributes_for :submission_rule, allow_destroy: true
  validates_associated :submission_rule
  validates_presence_of :submission_rule

  validates_presence_of :short_identifier
  validates_presence_of :description
  validates_presence_of :repository_folder
  validates_presence_of :due_date
  validates_presence_of :marking_scheme_type
  validates_presence_of :group_min
  validates_presence_of :group_max
  validates_presence_of :notes_count
  # "validates_presence_of" for boolean values.
  validates_inclusion_of :allow_web_submits, in: [true, false]
  validates_inclusion_of :vcs_submit, in: [true, false]
  validates_inclusion_of :display_grader_names_to_students, in: [true, false]
  validates_inclusion_of :is_hidden, in: [true, false]
  validates_inclusion_of :enable_test, in: [true, false]
  validates_inclusion_of :assign_graders_to_criteria, in: [true, false]

  validate :minimum_number_of_groups

  before_save :reset_collection_time

  # Call custom validator in order to validate the :due_date attribute
  # date: true maps to DateValidator (custom_name: true maps to CustomNameValidator)
  # Look in lib/validators/* for more info
  validates :due_date, date: true
  after_save :update_assigned_tokens

  # Set the default order of assignments: in ascending order of due_date
  default_scope { order('due_date ASC') }

  # Export a YAML formatted string created from the assignment rubric criteria.
  def export_rubric_criteria_yml
    criteria = self.rubric_criteria
    final = ActiveSupport::OrderedHash.new
    criteria.each do |criterion|
      inner = ActiveSupport::OrderedHash.new
      inner['weight'] =  criterion['weight']
      inner['level_0'] = {
        'name' =>  criterion['level_0_name'] ,
        'description' =>  criterion['level_0_description']
      }
      inner['level_1'] = {
        'name' =>  criterion['level_1_name'] ,
        'description' =>  criterion['level_1_description']
      }
      inner['level_2'] = {
        'name' =>  criterion['level_2_name'] ,
        'description' =>  criterion['level_2_description']
      }
      inner['level_3'] = {
        'name' =>  criterion['level_3_name'] ,
        'description' =>  criterion['level_3_description']
      }
      inner['level_4'] = {
        'name' =>  criterion['level_4_name'] ,
        'description' => criterion['level_4_description']
      }
      criteria_yml = { "#{criterion['rubric_criterion_name']}" => inner }
      final = final.merge(criteria_yml)
    end
    final.to_yaml
  end

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

  def past_collection_date?
    Time.zone.now > submission_rule.calculate_collection_time
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

  def total_mark
    total = 0
    if self.marking_scheme_type == 'rubric'
      rubric_criteria.each do |criterion|
        total = total + criterion.weight * 4
      end
    else
      total = flexible_criteria.sum('max')
    end
    total.round(2)
  end

  # calculates summary statistics of released results for this assignment
  def update_results_stats
    marks = Result.student_marks_by_assignment(id)
    # No marks released for this assignment.
    return false if marks.empty?

    self.results_fails = marks.count { |mark| mark < total_mark / 2.0 }
    self.results_zeros = marks.count(&:zero?)

    # Avoid division by 0.
    self.results_average, self.results_median =
      if total_mark.zero?
        [0, 0]
      else
        # Calculates average and median in percentage.
        [average(marks), median(marks)].map do |stat|
          (stat * 100 / total_mark).round(2)
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
            Result::MARKING_STATES[:partial]
          outstanding_count += 1
        end
      end
    end
    self.outstanding_remark_request_count = outstanding_count
    self.save
  end

  def total_criteria_weight
    factor = 10.0 ** 2
    (rubric_criteria.sum('weight') * factor).floor / factor
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

    row.map! { |item| item.strip }

    group = Group.where(group_name: row.first).first

    unless group.nil?
      if group.repo_name != row[1]
        # CASE: Group already exits but the repo name is different
        duplicate_group_error = I18n.t('csv.group_with_different_repo',
                                       group_name: row[0])
        return duplicate_group_error
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
              return duplicate_group_error
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
              return duplicate_group_error
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
    if repository_already_exists?(repo_name)
      repository_error = I18n.t('csv.repository_already_exists',
                                group_name: row[0],
                                repo_path: errors.get(:repo_name).last)
      errors.delete(:repo_name)
      return repository_error
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

  # Get a simple CSV report of marks for this assignment
  def get_simple_csv_report
    students = Student.all
    out_of = self.total_mark
    CSV.generate do |csv|
       students.each do |student|
         final_result = []
         final_result.push(student.user_name)
         grouping = student.accepted_grouping_for(self.id)
         if grouping.nil? || !grouping.has_submission?
           final_result.push('')
         else
           submission = grouping.current_submission_used
           final_result.push(submission.get_latest_result.total_mark / out_of * 100)
         end
         csv << final_result
       end
    end
  end

  # Get a detailed CSV report of marks (includes each criterion)
  # for this assignment. Produces slightly different reports, depending
  # on which criteria type has been used the this assignment.
  def get_detailed_csv_report
    # which marking scheme do we have?
    if self.marking_scheme_type == MARKING_SCHEME_TYPE[:flexible]
      get_detailed_csv_report_flexible
    else
      # default to rubric
      get_detailed_csv_report_rubric
    end
  end

  # Get a detailed CSV report of rubric based marks
  # (includes each criterion) for this assignment.
  # Produces CSV rows such as the following:
  #   student_name,95.22222,3,4,2,5,5,4,0/2
  # Criterion values should be read in pairs. I.e. 2,3 means
  # a student scored 2 for a criterion with weight 3.
  # Last column are grace-credits.
  def get_detailed_csv_report_rubric
    out_of = self.total_mark
    students = Student.all
    rubric_criteria = self.rubric_criteria
    CSV.generate do |csv|
      students.each do |student|
        final_result = []
        final_result.push(student.user_name)
        grouping = student.accepted_grouping_for(self.id)
        if grouping.nil? || !grouping.has_submission?
          # No grouping/no submission
          final_result.push('')                         # total percentage
          final_result.push('0')                        # total_grade
          rubric_criteria.each do |rubric_criterion|
            final_result.push('')                       # mark
            final_result.push(rubric_criterion.weight)  # weight
          end
          final_result.push('')                         # extra-mark
          final_result.push('')                         # extra-percentage
        else
          submission = grouping.current_submission_used
          final_result.push(submission.get_latest_result.total_mark / out_of * 100)
          final_result.push(submission.get_latest_result.total_mark)
          rubric_criteria.each do |rubric_criterion|
            mark = submission.get_latest_result
                             .marks
                             .where(markable_id: rubric_criterion.id,
                                    markable_type: 'RubricCriterion')
                             .first
            if mark.nil?
              final_result.push('')
            else
              final_result.push(mark.mark || '')
            end
            final_result.push(rubric_criterion.weight)
          end
          final_result.push(submission.get_latest_result.get_total_extra_points)
          final_result.push(submission.get_latest_result.get_total_extra_percentage)
        end
        # push grace credits info
        grace_credits_data = student.remaining_grace_credits.to_s + '/' + student.grace_credits.to_s
        final_result.push(grace_credits_data)

        csv << final_result
      end
    end
  end

  # Get a detailed CSV report of flexible criteria based marks
  # (includes each criterion, with it's out-of value) for this assignment.
  # Produces CSV rows such as the following:
  #   student_name,95.22222,3,4,2,5,5,4,0/2
  # Criterion values should be read in pairs. I.e. 2,3 means 2 out-of 3.
  # Last column are grace-credits.
  def get_detailed_csv_report_flexible
    out_of = self.total_mark
    students = Student.all
    flexible_criteria = self.flexible_criteria
    CSV.generate do |csv|
      students.each do |student|
        final_result = []
        final_result.push(student.user_name)
        grouping = student.accepted_grouping_for(self.id)
        if grouping.nil? || !grouping.has_submission?
          # No grouping/no submission
          final_result.push('')                 # total percentage
          final_result.push('0')                # total_grade
          flexible_criteria.each do |criterion| ##  empty criteria
            final_result.push('')               # mark
            final_result.push(criterion.max)    # out-of
          end
          final_result.push('')                 # extra-marks
          final_result.push('')                 # extra-percentage
        else
          # Fill in actual values, since we have a grouping
          # and a submission.
          submission = grouping.current_submission_used
          final_result.push(submission.get_latest_result.total_mark / out_of * 100)
          final_result.push(submission.get_latest_result.total_mark)
          flexible_criteria.each do |criterion|
            mark = submission.get_latest_result
                             .marks
                             .where(markable_id: criterion.id,
                                    markable_type: 'FlexibleCriterion')
                             .first
            if mark.nil?
              final_result.push('')
            else
              final_result.push(mark.mark || '')
            end
            final_result.push(criterion.max)
          end
          final_result.push(submission.get_latest_result.get_total_extra_points)
          final_result.push(submission.get_latest_result.get_total_extra_percentage)
        end
        # push grace credits info
        grace_credits_data = student.remaining_grace_credits.to_s + '/' + student.grace_credits.to_s
        final_result.push(grace_credits_data)

        csv << final_result
      end
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
    # grabbing the most up-to-date count of the rubric criteria.
    self.rubric_criteria.count + 1
  end

  # Returns the class of the criteria that belong to this assignment.
  def criterion_class
    if marking_scheme_type == MARKING_SCHEME_TYPE[:flexible]
      FlexibleCriterion
    elsif marking_scheme_type == MARKING_SCHEME_TYPE[:rubric]
      RubricCriterion
    else
      nil
    end
  end

  def get_criteria
    if self.marking_scheme_type == 'rubric'
      self.rubric_criteria
    else
      self.flexible_criteria
    end
  end

  def criteria_count
    if self.marking_scheme_type == 'rubric'
      self.rubric_criteria.size
    else
      self.flexible_criteria.size
    end
  end

  # Returns an array with the number of groupings who scored between
  # certain percentage ranges [0-5%, 6-10%, ...]
  # intervals defaults to 20
  def grade_distribution_as_percentage(intervals=20)
    distribution = Array.new(intervals, 0)
    out_of = self.total_mark

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
      ta_memberships.where(user_id: ta_id).find_each do |x|
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
    if marking_scheme_type == 'rubric'
      criterion = rubric_criteria.find_by(
        rubric_criterion_name: criterion_name)
    else
      criterion = flexible_criteria.find_by(
        flexible_criterion_name: criterion_name)
    end

    if criterion.nil?
      raise CSVInvalidLineError
    end

    unless graders.all? { |g| Ta.exists?(user_name: g) }
      raise CSVInvalidLineError
    end

    criterion.add_tas_by_user_name_array(graders)
  end
  
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
      t.update_tokens(tokens_per_day_was, tokens_per_day)
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
