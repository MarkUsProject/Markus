include CsvHelper
require 'csv_invalid_line_error'
class Assignment < ActiveRecord::Base

  MARKING_SCHEME_TYPE = {
    :flexible => 'flexible',
    :rubric => 'rubric'
  }

  has_many :automated_tests
  has_many :rubric_criteria,
           :class_name => "RubricCriterion",
           :order => :position
  has_many :flexible_criteria,
           :class_name => "FlexibleCriterion",
           :order => :position
  has_many :assignment_files
  has_many :test_support_files
  has_many :test_scripts
  has_many :criterion_ta_associations
  has_one :submission_rule
  has_one :assignment_stat
  accepts_nested_attributes_for :submission_rule, :allow_destroy => true
  accepts_nested_attributes_for :assignment_files, :allow_destroy => true
  accepts_nested_attributes_for :test_scripts, :allow_destroy => true
  accepts_nested_attributes_for :test_support_files, :allow_destroy => true
  accepts_nested_attributes_for :assignment_stat, :allow_destroy => true

  has_many :annotation_categories

  has_many :groupings
  has_many :ta_memberships,
           :class_name => "TaMembership",
           :through => :groupings
  has_many :student_memberships, :through => :groupings
  has_many :tokens, :through => :groupings

  has_many :submissions, :through => :groupings
  has_many :groups, :through => :groupings

  has_many :notes, :as => :noteable, :dependent => :destroy

  has_many :section_due_dates
  accepts_nested_attributes_for :section_due_dates

  validates_associated :assignment_files

  validates_presence_of :repository_folder
  validates_presence_of :short_identifier, :group_min
  validates_uniqueness_of :short_identifier, :case_sensitive => true

  validates_numericality_of :group_min,
                            :only_integer => true,
                            :greater_than => 0
  validates_numericality_of :group_max, :only_integer => true
  validates_numericality_of :tokens_per_day,
                            :only_integer => true,
                            :greater_than_or_equal_to => 0

  validates_associated :submission_rule
  validates_associated :assignment_stat
  validates_presence_of :submission_rule

  validates_presence_of :marking_scheme_type

  # since allow_web_submits is a boolean, validates_presence_of does not work:
  # see the Rails API documentation for validates_presence_of (Model
  # validations)
  validates_inclusion_of :allow_web_submits, :in => [true, false]
  validates_inclusion_of :display_grader_names_to_students, :in => [true, false]
  validates_inclusion_of :enable_test, :in => [true, false]
  validates_inclusion_of :assign_graders_to_criteria, :in => [true, false]

  before_save :reset_collection_time
  validate :minimum_number_of_groups, :check_timezone
  after_save :update_assigned_tokens

  # Export a YAML formatted string created from the assignment rubric criteria.
  def export_rubric_criteria_yml
    criteria = self.rubric_criteria
    final = Hash.new
    criteria.each do |criterion|
      inner = ActiveSupport::OrderedHash.new
      inner["weight"] =  criterion["weight"]
      inner["level_0"] = {
        "name"=>  criterion["level_0_name"] ,
        "description"=>  criterion["level_0_description"]
      }
      inner["level_1"] = {
        "name"=>  criterion["level_1_name"] ,
        "description"=>  criterion["level_1_description"]
      }
      inner["level_2"] = {
        "name"=>  criterion["level_2_name"] ,
        "description"=>  criterion["level_2_description"]
      }
      inner["level_3"] = {
        "name"=>  criterion["level_3_name"] ,
        "description"=>  criterion["level_3_description"]
      }
      inner["level_4"] = {
        "name"=>  criterion["level_4_name"] ,
        "description"=> criterion["level_4_description"]
      }
      criteria_yml = {"#{criterion["rubric_criterion_name"]}" => inner}
      final = final.merge(criteria_yml)
    end
    return final.to_yaml
  end

  def minimum_number_of_groups
    if (group_max && group_min) && group_max < group_min
      errors.add(:group_max, "must be greater than the minimum number of groups")
      return false
    end
  end

  def check_timezone
    if Time.zone.parse(due_date.to_s).nil?
      errors.add :due_date, 'is not a valid date'
      return false
    end
  end

  # Are we past all the due dates for this assignment?
  def past_due_date?
    # If no section due dates
    if !self.section_due_dates_type && self.section_due_dates.empty?
      return !due_date.nil? && Time.zone.now > due_date
    # If section due dates
    else
      self.section_due_dates.each do |d|
        if !d.due_date.nil? && Time.zone.now > d.due_date
          return true
        end
      end
      return false
    end
  end

  # Are we past the due date for this assignment, for this grouping ?
  def section_past_due_date?(grouping)
    if self.section_due_dates_type and !grouping.inviter.section.nil?
        section_due_date =
    SectionDueDate.due_date_for(grouping.inviter.section, self)
        return !section_due_date.nil? && Time.zone.now > section_due_date
    else
      self.past_due_date?
    end
  end

  # return the due date for a section
  def section_due_date(section)
    if self.section_due_dates_type
      if !section.nil?
        return SectionDueDate.due_date_for(section, self)
      end
    end
    return self.due_date
  end

  # Calculate the latest due date. Used to calculate the collection time
  def latest_due_date
    if !self.section_due_dates_type
      return self.due_date
    else
      due_date = self.due_date
      self.section_due_dates.each do |d|
        if !d.due_date.nil? && due_date < d.due_date
          due_date = d.due_date
        end
      end
      return due_date
    end
  end

  def past_collection_date?
    return Time.zone.now > submission_rule.calculate_collection_time
  end

  def past_remark_due_date?
    return !remark_due_date.nil? && Time.zone.now > remark_due_date
  end

  # Returns a Submission instance for this user depending on whether this
  # assignment is a group or individual assignment
  def submission_by(user) #FIXME: needs schema updates

    # submission owner is either an individual (user) or a group
    owner = self.group_assignment? ? self.group_by(user.id) : user
    return nil unless owner

    # create a new submission for the owner
    # linked to this assignment, if it doesn't exist yet

    # submission = owner.submissions.find_or_initialize_by_assignment_id(id)
    # submission.save if submission.new_record?
    # return submission

    assignment_groupings = user.active_groupings.delete_if {|grouping|
      grouping.assignment.id != self.id
    }

    unless assignment_groupings.empty?
      return assignment_groupings.first.submissions.first
    else
      return nil
    end
  end

  # Return true if this is a group assignment; false otherwise
  def group_assignment?
    invalid_override || group_min != 1 || group_max > 1
  end

  # Returns the group by the user for this assignment. If pending=true,
  # it will return the group that the user has a pending invitation to.
  # Returns nil if user does not have a group for this assignment, or if it is
  # not a group assignment
  def group_by(uid, pending=false)
    return nil unless group_assignment?

    # condition = "memberships.user_id = ?"
    # condition += " and memberships.status != 'rejected'"
    # add non-pending status clause to condition
    # condition += " and memberships.status != 'pending'" unless pending
    # groupings.find(:first, :include => :memberships, :conditions => [condition, uid]) #FIXME: needs schema update

    #FIXME: needs to be rewritten using a proper query...
    return User.find(uid).accepted_grouping_for(self.id)
  end

  # Make a list of students without any groupings
  def no_grouping_students_list
   @students = Student.all(:order => :last_name, :conditions => {:hidden => false})
   @students_list = []
   @students.each do |s|
     if !s.has_accepted_grouping_for?(self.id)
       @students_list.push(s)
      end
   end
   return @students_list
  end

  def display_for_note
    return short_identifier
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
    return total
  end

  # calculates the average of released results for this assignment
  def set_results_average
    groupings = Grouping.find_all_by_assignment_id(self.id)
    results_count = 0
    results_sum = 0
    groupings.each do |grouping|
      submission = grouping.current_submission_used
      if !submission.nil?
        if submission.has_result? && submission.remark_submitted?
          result = submission.remark_result
        elsif submission.has_result?
          result = submission.result
        end
        if result.released_to_students
          results_sum += result.total_mark
          results_count += 1
        end
      end
    end
    if results_count == 0
      return false # no marks released for this assignment
    end
    # Need to avoid divide by zero
    if results_sum == 0
      self.results_average = 0
      return self.save
    end
    avg_quantity = results_sum / results_count
    # compute average in percent
    self.results_average = (avg_quantity * 100 / self.total_mark)
    self.save
  end

  def total_criteria_weight
    factor = 10.0 ** 2
    return (rubric_criteria.sum('weight') * factor).floor / factor
  end

  def add_group(new_group_name=nil)
    if self.group_name_autogenerated
      group = Group.new
      group.save(:validate => false)
      group.group_name = group.get_autogenerated_group_name
      group.save
    else
      return nil if new_group_name.nil?
      if Group.find(:first, :conditions => {:group_name => new_group_name})
        group = Group.find(:first, :conditions => {:group_name =>       new_group_name})
        if !self.groupings.find_by_group_id(group.id).nil?
          raise "Group #{new_group_name} already exists"
        end
      else
        group = Group.new
        group.group_name = new_group_name
        group.save
      end
    end
    grouping = Grouping.new
    grouping.group = group
    grouping.assignment = self
    grouping.save
    return grouping
  end


  # Create all the groupings for an assignment where students don't work
  # in groups.
  def create_groupings_when_students_work_alone
     @students = Student.find(:all)
     for student in @students do
       if !student.has_accepted_grouping_for?(self.id)
        student.create_group_for_working_alone_student(self.id)
       end
     end
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
        if !unhidden_student_memberships.empty?
          #create the groupings
          grouping = Grouping.new
          grouping.group_id = g.group_id
          grouping.assignment_id = self.id
          grouping.admin_approved = g.admin_approved
          raise "Could not save grouping" if !grouping.save
          all_memberships = unhidden_student_memberships + unhidden_ta_memberships
          all_memberships.each do |m|
            membership = Membership.new
            membership.user_id = m.user_id
            membership.type = m.type
            membership.membership_status = m.membership_status
            raise "Could not save membership" if !(grouping.memberships << membership)
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
  # Any member names that do not exist in the database will simply be ignored
  # (This makes it possible to have empty groups created from a bad csv row)
  def add_csv_group(row)
    return if row.length == 0

    # Note: We cannot use find_or_create_by here, because it has its own
    # save semantics. We need to set and save attributes in a very particular
    # order, so that everything works the way we want it to.
    group = Group.find_by_group_name(row[0])
    if group.nil?
      group = Group.new
      group.group_name = row[0]
    end

    # Since repo_name of "group" will be set before the first save call, the
    # set repo_name will be used instead of the autogenerated name. See
    # set_repo_name and build_repository in the groups model. Also, see
    # create_group_for_working_alone_student in the students model for
    # similar semantics.
    if is_candidate_for_setting_custom_repo_name?(row)
      # Do this only if user_name exists and is a student.
      if !Student.find_by_user_name(row[2]).nil?
        group.repo_name = row[0]
      else
        # Student name does not exist, use provided repo_name
        group.repo_name = row[1].strip # remove whitespace
      end
    end

    # If we are not repository admin, set the repository name as provided
    # in the csv upload file
    if !group.repository_admin?
      group.repo_name = row[1].strip # remove whitespace
    end
    # Note: after_create hook build_repository might raise
    # Repository::RepositoryCollision. If it does, it adds the colliding
    # repo_name to errors.on_base. This is how we can detect repo
    # collisions here. Unfortunately, we can't raise an exception
    # here, because we still want the grouping to be created. This really
    # shouldn't happen anyway, because the lookup earlier should prevent
    # repo collisions e.g. when uploading the same CSV file twice.
    group.save
    if !group.errors[:base].blank?
      collision_error = I18n.t("csv.repo_collision_warning",
                          { :repo_name => group.errors.on_base,
                            :group_name => row[0] })
    end

    # Create a new Grouping for this assignment and the newly
    # crafted group
    grouping = Grouping.new(:assignment => self, :group => group)
    grouping.save

    # Form groups
    start_index_group_members = 2 # first field is the group-name, second the repo name, so start at field 3
    (start_index_group_members..(row.length - 1)).each do |i|
      student = Student.find_by_user_name(row[i].strip) # remove whitespace
      if !student.nil?
        if (grouping.student_membership_number == 0)
          # Add first valid member as inviter to group.
          grouping.group_id = group.id
          grouping.save # grouping has to be saved, before we can add members
          grouping.add_member(student, StudentMembership::STATUSES[:inviter])
        else
          grouping.add_member(student)
        end
      end

    end
    return collision_error
  end

  # Updates repository permissions for all groupings of
  # an assignment. This is a handy method, if for example grouping
  # creation/deletion gets rolled back. The rollback does not
  # reestablish proper repository permissions.
  def update_repository_permissions_forall_groupings
    # IMPORTANT: need to reload from DB
    self.reload
    groupings.each do |grouping|
      grouping.update_repository_permissions
    end
  end

  def grouped_students
    result_students = []
    student_memberships.each do |student_membership|
      result_students.push(student_membership.user)
    end
    return result_students
  end

  def ungrouped_students
    Student.all(:conditions => {:hidden => false}) - grouped_students
  end

  def valid_groupings
    result = []
    groupings.all(:include => [{:student_memberships => :user}]).each do |grouping|
      if grouping.admin_approved || grouping.student_memberships.count >= group_min
        result.push(grouping)
      end
    end
    return result
  end

  def invalid_groupings
    return groupings - valid_groupings
  end

  def assigned_groupings
    return groupings.all(:joins => :ta_memberships, :include => [{:ta_memberships => :user}]).uniq
  end

  def unassigned_groupings
    return groupings - assigned_groupings
  end

  # Get a list of subversion client commands to be used for scripting
  def get_svn_export_commands
    svn_commands = [] # the commands to be exported

    self.groupings.each do |grouping|
      submission = grouping.current_submission_used
      if !submission.nil?
        svn_commands.push("svn export -r #{submission.revision_number} #{grouping.group.repository_external_access_url}/#{self.repository_folder} \"#{grouping.group.group_name}\"")
      end
    end
    return svn_commands
  end

  # Get a list of group_name, repo-url pairs
  def get_svn_repo_list
    string = CsvHelper::Csv.generate do |csv|
      self.groupings.each do |grouping|
        group = grouping.group
        csv << [group.group_name,group.repository_external_access_url]
      end
    end
    return string
  end

  # Get a simple CSV report of marks for this assignment
  def get_simple_csv_report
    students = Student.all
    out_of = self.total_mark
    csv_string = CsvHelper::Csv.generate do |csv|
       students.each do |student|
         final_result = []
         final_result.push(student.user_name)
         grouping = student.accepted_grouping_for(self.id)
         if grouping.nil? || !grouping.has_submission?
           final_result.push('')
         else
           submission = grouping.current_submission_used
           final_result.push(submission.result.total_mark / out_of * 100)
         end
         csv << final_result
       end
    end
    return csv_string
  end

  # Get a detailed CSV report of marks (includes each criterion)
  # for this assignment. Produces slightly different reports, depending
  # on which criteria type has been used the this assignment.
  def get_detailed_csv_report
    # which marking scheme do we have?
    if self.marking_scheme_type == MARKING_SCHEME_TYPE[:flexible]
      return get_detailed_csv_report_flexible
    else
      # default to rubric
      return get_detailed_csv_report_rubric
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
    csv_string = CsvHelper::Csv.generate do |csv|
      students.each do |student|
        final_result = []
        final_result.push(student.user_name)
        grouping = student.accepted_grouping_for(self.id)
        if grouping.nil? || !grouping.has_submission?
          # No grouping/no submission
          final_result.push('')                         # total percentage
          rubric_criteria.each do |rubric_criterion|
            final_result.push('')                       # mark
            final_result.push(rubric_criterion.weight)  # weight
          end
          final_result.push('')                         # extra-mark
          final_result.push('')                         # extra-percentage
        else
          submission = grouping.current_submission_used
          final_result.push(submission.result.total_mark / out_of * 100)
          rubric_criteria.each do |rubric_criterion|
            mark = submission.result.marks.find_by_markable_id_and_markable_type(rubric_criterion.id, "RubricCriterion")
            if mark.nil?
              final_result.push('')
            else
              final_result.push(mark.mark || '')
            end
            final_result.push(rubric_criterion.weight)
          end
          final_result.push(submission.result.get_total_extra_points)
          final_result.push(submission.result.get_total_extra_percentage)
        end
        # push grace credits info
        grace_credits_data = student.remaining_grace_credits.to_s + "/" + student.grace_credits.to_s
        final_result.push(grace_credits_data)

        csv << final_result
      end
    end
    return csv_string
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
    csv_string = CsvHelper::Csv.generate do |csv|
      students.each do |student|
        final_result = []
        final_result.push(student.user_name)
        grouping = student.accepted_grouping_for(self.id)
        if grouping.nil? || !grouping.has_submission?
          # No grouping/no submission
          final_result.push('')                 # total percentage
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
          final_result.push(submission.result.total_mark / out_of * 100)
          flexible_criteria.each do |criterion|
            mark = submission.result.marks.find_by_markable_id_and_markable_type(criterion.id, "FlexibleCriterion")
            if mark.nil?
              final_result.push('')
            else
              final_result.push(mark.mark || '')
            end
            final_result.push(criterion.max)
          end
          final_result.push(submission.result.get_total_extra_points)
          final_result.push(submission.result.get_total_extra_percentage)
        end
        # push grace credits info
        grace_credits_data = student.remaining_grace_credits.to_s + "/" + student.grace_credits.to_s
        final_result.push(grace_credits_data)

        csv << final_result
      end
    end
    return csv_string
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
    return self.rubric_criteria.count + 1
  end

  def get_criteria
    if self.marking_scheme_type == 'rubric'
       return self.rubric_criteria
    else
       return self.flexible_criteria
    end
  end

  def criteria_count
    if self.marking_scheme_type == 'rubric'
       return self.rubric_criteria.size
    else
       return self.flexible_criteria.size
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
    groupings = self.groupings.all(:include => [{:current_submission_used => :result}])

    groupings.each do |grouping|
      submission = grouping.current_submission_used
      if !submission.nil? && submission.has_result?
        result = submission.result
        if result.marking_state == Result::MARKING_STATES[:complete]
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

    return distribution
  end

  # Returns all the TAs associated with the assignment
  def tas
    ids = self.ta_memberships.map { |m| m.user_id }
    return Ta.find(ids)
  end

  # Returns all the submissions that have been graded
  def graded_submissions
    return self.submissions.select { |submission| submission.result.marking_state == Result::MARKING_STATES[:complete] }
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
      return true
    else
      return false
    end
  end

  def reset_collection_time
    submission_rule.reset_collection_time
  end

  def update_assigned_tokens
    self.tokens.each do |t|
      t.update_tokens(self.tokens_per_day_was, self.tokens_per_day)
    end
  end
end
