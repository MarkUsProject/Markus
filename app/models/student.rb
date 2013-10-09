class Student < User

  has_many :accepted_groupings, :class_name => 'Grouping', :through => :memberships, :conditions => {'memberships.membership_status' => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]}, :source => :grouping

  has_many :pending_groupings, :class_name => 'Grouping', :through => :memberships, :conditions => {'memberships.membership_status' => StudentMembership::STATUSES[:pending]}, :source => :grouping

  has_many :rejected_groupings, :class_name => 'Grouping', :through => :memberships, :conditions => {'memberships.membership_status' => StudentMembership::STATUSES[:rejected]}, :source => :grouping

  has_many :student_memberships, :foreign_key => 'user_id'

  has_many :grace_period_deductions, :through => :memberships

  belongs_to :section
  accepts_nested_attributes_for :section

  validates_numericality_of :grace_credits, :only_integer => true,
    :greater_than_or_equal_to => 0

  CSV_UPLOAD_ORDER = USER_STUDENT_CSV_UPLOAD_ORDER
  SESSION_TIMEOUT = USER_STUDENT_SESSION_TIMEOUT

  # Returns true if this student has a Membership in a Grouping for an
  # Assignment with id 'aid', where that Membership.membership_status is either
  # 'accepted' or 'inviter'
  def has_accepted_grouping_for?(aid)
    !accepted_grouping_for(aid).nil?
  end

  # Returns the Grouping for an Assignment with id 'aid' if this Student has
  # a Membership in that Grouping where the membership.status is 'accepted'
  # or 'inviter'
  def accepted_grouping_for(aid)
    accepted_groupings.find_by_assignment_id(aid)
  end

  def has_pending_groupings_for?(aid)
    pending_groupings_for(aid).size > 0
  end

  def pending_groupings_for(aid)
    pending_groupings.find_all_by_assignment_id(aid)
  end

  def remaining_grace_credits
    return @remaining_grace_credits if !@remaining_grace_credits.nil?
    total_deductions = 0
    grace_period_deductions.each do |grace_period_deduction|
      total_deductions += grace_period_deduction.deduction
    end
    @remaining_grace_credits = grace_credits - total_deductions
  end

  def display_for_note
    user_name + ': ' + last_name + ', ' + first_name
  end

  # return pending memberships for a specific assignment
  def pending_memberships_for(aid)
    groupings = self.pending_groupings_for(aid)
    if groupings
      pending_memberships = []
      groupings.each do |grouping|
         pending_memberships.push(StudentMembership.find_by_grouping_id_and_user_id(grouping.id, self.id))
      end
      return pending_memberships
    end
    nil
  end


  # Returns the Membership for a Grouping for an Assignment with id 'aid' if
  # this Student is a member with either 'accepted' or 'invitier' membership
  # status

  def memberships_for(aid)
     @student = self
     @memberships = StudentMembership.all(:conditions => {:user_id => @student.id})
     @memberships.each do |m|
       if m.grouping.assignment_id != aid
         @memberships.delete(m)
       end
     end
     @memberships
  end

  # invites a student
  def invite(gid)
    unless self.hidden
      membership = StudentMembership.new
      membership.grouping_id = gid
      membership.membership_status = StudentMembership::STATUSES[:pending]
      membership.user_id = self.id
      membership.save
      # update repo permissions (for accepted memberships - includes inviter)
      # if grouping is valid
      grouping = Grouping.find(gid)
      grouping.update_repository_permissions
    end
  end

  def destroy_all_pending_memberships(aid)
    self.pending_groupings_for(aid).each do |grouping|
      membership = grouping.student_memberships.find_by_user_id(self.id)
      membership.destroy
    end
  end

  # creates a group and a grouping for a student to work alone, for
  # assignment aid
  def create_group_for_working_alone_student(aid)
    ActiveRecord::Base.transaction do
      @assignment = Assignment.find(aid)
      @grouping = Grouping.new
      @grouping.assignment_id = @assignment.id
      if !Group.first(:conditions => {:group_name => self.user_name}).nil?
        @group = Group.first(:conditions => {:group_name => self.user_name})
      else
        @group = Group.new(:group_name => self.user_name)
        # We want to have the user_name as repository name,
        # so we have to set the repo_name before we save the group.
        # We do that only if the assignment is set up to be a
        # non-web-submit assignment.
        unless @assignment.allow_web_submits
          @group.repo_name = self.user_name
        end
        unless @group.save
          m_logger = MarkusLogger.instance
          m_logger.log("Could not create a group for Student '#{self.user_name}'. The group was #{@group.inspect} - errors: #{@group.errors.inspect}", MarkusLogger::ERROR)
          raise 'Sorry!  For some reason, your group could not be created.  Please wait a few seconds, then hit refresh to try again.  If you come back to this page, you should inform the course instructor.'
        end
      end

      @grouping.group = @group
      begin
        unless @grouping.save
          m_logger = MarkusLogger.instance
          m_logger.log("Could not create a grouping for Student '#{self.user_name}'. The grouping was:  #{@grouping.inspect} - errors: #{@grouping.errors.inspect}", MarkusLogger::ERROR)
          raise 'Sorry!  For some reason, your grouping could not be created.  Please wait a few seconds, and hit refresh to try again.  If you come back to this page, you should inform the course instructor.'
        end
      # This exception will only be thrown when we try to save to a grouping that already exists
      rescue ActiveRecord::RecordNotUnique => e
        # transaction has failed, so quit it
        return false
      end

      # We give students the tokens for the test framework
      @grouping.give_tokens

      # Create the membership
      @member = StudentMembership.new(:grouping_id => @grouping.id,
              :membership_status => StudentMembership::STATUSES[:inviter],
              :user_id => self.id)
      @member.save

      # Destroy all the other memberships for this assignment
      self.destroy_all_pending_memberships(@assignment.id)

      # Update repo permissions if need be. This has to happen
      # after memberships have been established.
      @grouping.update_repository_permissions
    end
    return true
  end

  def create_autogenerated_name_group(aid)
    assignment = Assignment.find(aid)
    unless assignment.group_name_autogenerated
      raise 'Assignment does not allow for groups with autogenerated names'
    end

    group = Group.new
    group.save(:validate => false)
    group.group_name = group.get_autogenerated_group_name
    group.save

    grouping = Grouping.new
    grouping.assignment_id = aid
    grouping.group_id = group.id
    grouping.save

    # write repo permissions if need be
    grouping.update_repository_permissions

    member = StudentMembership.new(:grouping_id => grouping.id, :membership_status => StudentMembership::STATUSES[:inviter], :user_id => self.id)
    member.save
    self.destroy_all_pending_memberships(aid)
  end

  # This method is called, when a student joins a group(ing)
  def join(gid)
    membership = StudentMembership.find_by_grouping_id_and_user_id(gid, self.id)
    membership.membership_status = 'accepted'
    membership.save

    grouping = Grouping.find(gid)
    # write repo permissions if need be
    grouping.update_repository_permissions

    if grouping.is_valid?
      # We give students the tokens for the test framework
      grouping.give_tokens
    end

    other_memberships = self.pending_memberships_for(grouping.assignment_id)
    other_memberships.each do |m|
      m.membership_status = 'rejected'
      m.save
    end
  end

  # Hides a list of students and revokes repository
  # permissions (when exposed externally)
  def self.hide_students(student_id_list)
    update_list = {}
    student_id_list.each do |student_id|
      update_list[student_id] = {:hidden => true}
      # update repo permissions appropriately
      memberships = StudentMembership.find_by_user_id(student_id)
      if memberships
        unless memberships.instance_of?(Array)
          memberships = [memberships]
        end
        student = Student.find(student_id)
        memberships.each do |membership|
          group = membership.grouping.group
          group.access_repo do |repo|
            if membership.grouping.repository_external_commits_only? && membership.grouping.is_valid?
              begin
                repo.remove_user(student.user_name) # revoke repo permissions
              rescue Repository::UserNotFound
                # ignore case when user isn't there any more
              end
            end
          end
        end
      end
    end
    Student.update(update_list.keys, update_list.values)
  end

  # "Unhides" students not visible and grants repository
  # permissions (when exposed externally)
  def self.unhide_students(student_id_list)
    update_list = {}
    student_id_list.each do |student_id|
      update_list[student_id] = {:hidden => false}
      # update repo permissions appropriately
      memberships = StudentMembership.find_by_user_id(student_id)
      if memberships
        unless memberships.instance_of?(Array)
          memberships = [memberships]
        end
        student = Student.find(student_id)
        memberships.each do |membership|
          group = membership.grouping.group
          group.access_repo do |repo|
            if membership.grouping.repository_external_commits_only? && membership.grouping.is_valid?
              begin
                repo.add_user(student.user_name, Repository::Permission::READ_WRITE) # grant repo permissions
              rescue Repository::UserAlreadyExistent
                # ignore case if user has permissions already
              end
            end
          end
        end
      end
    end
    Student.update(update_list.keys, update_list.values)
  end

  def self.give_grace_credits(student_ids, number_of_grace_credits)
    students = Student.find(student_ids)
    students.each do |student|
      student.grace_credits += number_of_grace_credits.to_i
      if student.grace_credits < 0
        student.grace_credits = 0
      end
      student.save
    end
  end

  # Returns true when the student has a section
  def has_section?
    !self.section.nil?
  end

  # Updates the section of a list of students
  def self.update_section(students_ids, nsection)
    students_ids.each do |sid|
      Student.update(sid, {:section_id => nsection})
    end
  end

end
