module CourseSummariesHelper
  #
  #  Get JSON data for the table in the form of
  #  { id: student_id, user_name: student.user_name,
  #    first_name: student.first_name, last_name: student.last_name
  #    marks: [ // an array of marks for each assignment, null if no grade ] }
  #
  def get_table_json_data
    all_students = Student.where(type: 'Student');
    all_assignments = Assignment.all;

    studentList = all_students.map do |student|
      {
        :id => student.id,
        :user_name => student.user_name,
        :first_name => student.first_name,
        :last_name => student.last_name,
        :marks => \
          get_mark_for_all_assignments_for_student(student, all_assignments)
      }
    end
      studentList.to_json
  end

  # Get marks for all assignments for a student 
  def get_mark_for_all_assignments_for_student(student, all_assignments)
    marks = []
    all_assignments.each do |assignment|
      marks[assignment.id - 1] = \
      get_mark_for_assignment_and_student(assignment, student)
    end
    marks
  end

  # Get mark for a perticular assignment for a student
  def get_mark_for_assignment_and_student(assignment, student)
    grouping = get_grouping_for_user_for_assignment(student, assignment)
    if grouping
      submission = Submission.where(grouping_id: grouping.id).first
      if submission
        result = Result.where(submission_id: submission.id).first
        if result
          return result.total_mark
        end
      end
    end
    return nil
  end

  def get_grouping_for_user_for_assignment(student, assignment)
    memberships = Membership.where(user_id: student.id)
    if (memberships.count == 0)
      return nil
    end
    grouping = \
      get_grouping_for_assignment_for_membership(memberships, assignment)
    return grouping
  end

  def get_grouping_for_assignment_for_membership(memberships, assignment)
    memberships.each do |membership|
      grouping = Grouping.where(id: membership.grouping_id).first
      if (grouping.assignment_id == assignment.id)
        return grouping
      end
    end
    return nil
  end
end