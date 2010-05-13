class Assignment < ActiveRecord::Base 
  
  MARKING_SCHEME_TYPE = {
    :flexible => 'flexible',
    :rubric => 'rubric'
  }
  
  has_many :rubric_criteria, :class_name => "RubricCriterion", :order => :position
  has_many :flexible_criteria, :class_name => "FlexibleCriterion", :order => :position
  has_many :assignment_files
  has_one  :submission_rule 
  accepts_nested_attributes_for :submission_rule, :allow_destroy => true
  accepts_nested_attributes_for :assignment_files, :allow_destroy => true
  
  has_many :annotation_categories
  
  has_many :groupings
  has_many :ta_memberships, :through => :groupings
  has_many :student_memberships, :through => :groupings
  
  has_many :submissions, :through => :groupings
  has_many :groups, :through => :groupings
  
  has_many :notes, :as => :noteable, :dependent => :destroy
  
  validates_associated :assignment_files
  
  validates_presence_of     :repository_folder
  validates_presence_of     :short_identifier, :group_min
  validates_uniqueness_of   :short_identifier, :case_sensitive => true
  
  validates_numericality_of :group_min, :only_integer => true,  :greater_than => 0
  validates_numericality_of :group_max, :only_integer => true

  validates_associated :submission_rule
  validates_presence_of :submission_rule
  
  validates_presence_of :marking_scheme_type
  # since allow_web_submits is a boolean, validates_presence_of does not work:
  # see the Rails API documentation for validates_presence_of (Model validations)
  validates_inclusion_of :allow_web_submits, :in => [true, false] 
  validates_inclusion_of :display_grader_names_to_students, :in => [true, false]
  
  def validate
    if (group_max && group_min) && group_max < group_min
      errors.add(:group_max, "must be greater than the minimum number of groups")
    end
    if Time.zone.parse(due_date.to_s).nil?
      errors.add :due_date, 'is not a valid date'
    end
  end
  
  # Are we past the due date for this assignment?
  def past_due_date?
    return !due_date.nil? && Time.now > due_date
  end
  
  def past_collection_date?
    return Time.now > submission_rule.calculate_collection_time
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
    instructor_form_groups || group_min != 1 || group_max > 1
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
  
  # Make a list of the students an inviter can invite for his grouping
  # TODO check if this method is ever used anywhere [Not used anywhere as of 2010/03/30]
  # TODO unit tests
  def can_invite_for(gid)
    grouping = Grouping.find(gid)
    students = self.no_grouping_students_list
    students_list = []
    students.each do |s|
      if !grouping.pending?(s)
        # if assignment doesn't restrict groups member per sections
        if !self.section_groups_only
          students_list.push(s)
        else
          # if assignment restricts groupmembers per section
          if student.section == grouping.inviter.section
            students_list.push(s)
          end
        end
      end
    end
    return students_list
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
      submission = grouping.get_submission_used
      if !submission.nil? && submission.has_result?
        result = submission.result
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
      group.save(false)
      group.group_name = group.get_autogenerated_group_name
      group.save
    else
      return nil if new_group_name.nil?
      if Group.find(:first, :conditions => {:group_name => new_group_name})
        group = Group.find(:first, :conditions => {:group_name =>	new_group_name})
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
  # the passed in Array (format: [ groupname, repo_name, member, member, etc ]
  def add_csv_group(group)
    return nil if group.length <= 0
    # If a group with this name already exists, link the grouping to
    # this group. else create the group
    if Group.find(:first, :conditions => {:group_name => group[0]})
      @group = Group.find(:first, :conditions => {:group_name => group[0]})
    else
      @group = Group.new
      @group.group_name = group[0]  
      @group.save
    end
    
    # Group for grouping has to exist at this point
    @grouping = Grouping.new
    @grouping.assignment_id = self.id
    
    # If we are not repository admin, set the repository name as provided
    # in the csv upload file
    if !@group.repository_admin?
      @group.repo_name = group[1].strip # remove whitespace
      @group.save # save new repo_name
    end

    # Form groups
    users_not_found = []
    start_index_group_members = 2 # first field is the group-name, second the repo name, so start at field 3
    for i in start_index_group_members..(group.length-1) do
      student = Student.find_by_user_name(group[i].strip) # remove whitespace
      if student.nil?
        users_not_found << group[i].strip # use this in view to get some meaningful feedback
        return users_not_found
      end
      if (i > start_index_group_members)
        @grouping.add_member(student)
      else
        # Add first member as inviter to group.
        @grouping.group_id = @group.id
        @grouping.save # grouping has to be saved, before we can add members
        @grouping.add_member(student, StudentMembership::STATUSES[:inviter])
      end
    end
    return true
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
    self.submissions.each do |submission|
      grouping = submission.grouping
      svn_commands.push("svn export -r #{submission.revision_number} #{grouping.group.repository_external_access_url} \"#{grouping.group.group_name}\"")
    end
    return svn_commands
  end
  
  # Get a list of group_name, repo-url pairs
  def get_svn_repo_list
    string = FasterCSV.generate do |csv|
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
    csv_string = FasterCSV.generate do |csv|
       students.each do |student|
         final_result = []
         final_result.push(student.user_name)         
         grouping = student.accepted_grouping_for(self.id)
         if grouping.nil? || !grouping.has_submission?
           final_result.push('')
         else
           submission = grouping.get_submission_used
           final_result.push(submission.result.total_mark / out_of * 100)                    
         end
         csv << final_result
       end
    end
    return csv_string
  end
  
  # Get a detailed CSV report of marks (includes each criterion) for this assignment
  def get_detailed_csv_report
    out_of = self.total_mark
    students = Student.all
    rubric_criteria = self.rubric_criteria
    csv_string = FasterCSV.generate do |csv|
      students.each do |student|
        final_result = []
        final_result.push(student.user_name)
        grouping = student.accepted_grouping_for(self.id)
        if grouping.nil? || !grouping.has_submission?
          final_result.push('')
          rubric_criteria.each do |rubric_criterion|
            final_result.push('')
            final_result.push(rubric_criterion.weight)
          end
          final_result.push('')
          final_result.push('')
        else
          submission = grouping.get_submission_used
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
    return self.rubric_criteria.size + 1
  end
    
  def get_criteria
    if self.marking_scheme_type == 'rubric'
       return self.rubric_criteria
    else
       return self.flexible_criteria
    end
  end
  
end
