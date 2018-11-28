module GroupsHelper
  # Gets information needed to display students
  # in the table on the front-end. Returns
  # an array of hashes.
  def get_students_table_info
    students = Student.all
    student_memberships = StudentMembership
                          .includes(:user)
                          .where(grouping_id: @assignment.groupings)

    students_in_assignment = student_memberships.map do |membership|
      membership.user
    end

    students.map do |student|
      s = student.attributes
      s['assigned'] = students_in_assignment.include?(student)
      s
    end
  end

  # Gets information needed to display group info
  # on the front-end. Attributes include URLs for actions
  # such as validation, renaming, showing notes, etc.
  def get_groupings_table_info(target_assignment=nil)
    if target_assignment.nil?
      target_assignment = @assignment
    end

    groupings = target_assignment.groupings
                           .includes(:group,
                                     :student_memberships,
                                     :non_rejected_student_memberships,
                                     :students,
                                     :inviter)
    groupings.map do |grouping|
      g = grouping.attributes
      g[:name] = grouping.group.group_name
      g[:members] = grouping.student_memberships.map {|membership| [membership.user.id, membership.user.user_name, membership.membership_status]}#grouping.students
      g[:section] = grouping.section
      g[:valid] = grouping.is_valid?
      g
    end
  end
end
