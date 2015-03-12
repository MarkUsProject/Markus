module CourseSummariesHelper
  #
  #  Get JSON data for the table in the form of
  #  { id: student_id, user_name: student.user_name,
  #    first_name: student.first_name, last_name: student.last_name
  #    marks: { a_id: mark/null } }
  #
  def get_table_json_data
    all_students = Student.where(type: 'Student')
    all_assignments = Assignment.all

    student_list = all_students.map do |student|
      {
      id: student.id,
      user_name: student.user_name,
      first_name: student.first_name,
      last_name: student.last_name,
      marks: \
        get_mark_for_all_assignments_for_student(student, all_assignments)
      }
    end
    student_list.to_json
  end

  # Get marks for all assignments for a student
  def get_mark_for_all_assignments_for_student(student, all_assignments)
    marks = {}
    all_assignments.each do |assignment|
      marks[assignment.id] = \
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
  end

  def get_grouping_for_user_for_assignment(student, assignment)
    memberships = Membership.where(user_id: student.id)
    if (memberships.count == 0)
      return nil
    end
    get_grouping_for_assignment_for_membership(memberships, assignment)
  end

  def get_grouping_for_assignment_for_membership(memberships, assignment)
    memberships.each do |membership|
      grouping = Grouping.where(id: membership.grouping_id).first
      if (grouping.assignment_id == assignment.id)
        return grouping
      end
    end
    nil
  end

  # Return an object that contains an key for each assignment
  # and the value is the max mark or null if no marking scheme
  # is currently defined
  def get_max_mark_for_assignments
    max_marks = {}
    Assignment.all.each do |a|
      max_marks[a.id] = get_max_mark_for_assignment(a.id)
    end
    max_marks.to_json
  end

  # Get max mark for assignment with id a_id
  def get_max_mark_for_assignment(a_id)
    rubric_criterias = RubricCriterion.where(assignment_id: a_id)
    if (rubric_criterias.count == 0)
      return nil
    end
    max_mark = 0
    rubric_criterias.each do |rc|
      max_mark += rc.weight * 4
    end
    max_mark
  end

  # Return an object that contains a key for each marking
  # scheme. And the value is an object with keys as assignment ids
  # and the value the weight for that assignment
  def get_marking_weights_for_all_marking_schemes
    result = {}
    MarkingScheme.all.each do |ms|
      result[ms.id] = {}
      MarkingWeight.where(marking_scheme_id: ms.id).each do |mw|
        result[ms.id][mw.a_id] = mw.weight
      end
    end
    result.to_json
  end
end
