module CourseSummariesHelper
  #  Get JSON data for the table
  def get_table_json_data
    all_students = Student.where(type: 'Student')
    all_assignments = Assignment.all
    all_grade_entry_forms = GradeEntryForm.all

    student_list = all_students.map do |student|
      {
        id: student.id,
        user_name: student.user_name,
        first_name: student.first_name,
        last_name: student.last_name,
        assignment_marks:
          get_mark_for_all_assignments_for_student(student, all_assignments),
        grade_entry_form_marks:
          get_mark_for_all_gef_for_student(student, all_grade_entry_forms),
        weighted_marks:
          get_weighted_total_for_all_marking_schemes_for_student(student)
      }
    end
    student_list.to_json
  end

  # Get marks for all assignments for a student
  def get_mark_for_all_assignments_for_student(student, all_assignments)
    marks = {}
    all_assignments.each do |assignment|
      marks[assignment.id] =
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

  def get_mark_for_all_gef_for_student(student, all_grade_entry_forms)
    marks = {}
    all_grade_entry_forms.each do |gef|
      marks[gef.id] = get_mark_for_gef_and_student(gef, student)
    end
    marks
  end

  def get_mark_for_gef_and_student(gef, student)
    ges = GradeEntryStudent.where(grade_entry_form_id: gef.id,
                                  user_id: student.id)
    if ges != []
      return ges.first.total_grade
    end
    nil
  end

  def get_max_mark_for_grade_entry_forms
    max_marks = {}
    GradeEntryForm.all.each do |gef|
      max_marks[gef.id] = get_max_mark_for_grade_entry_from(gef.id)
    end
    max_marks
  end

  def get_max_mark_for_grade_entry_from(gef_id)
    total = 0
    GradeEntryItem.where(grade_entry_form_id: gef_id).each do |gei|
      total += gei.out_of
    end
    total
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
    result
  end

  def get_weighted_total_for_all_marking_schemes_for_student(student)
    result = {}

    assignment_marks =
      get_mark_for_all_assignments_for_student(student, Assignment.all)
    gef_marks = get_mark_for_all_gef_for_student(student, GradeEntryForm.all)

    MarkingScheme.all.each do |ms|
      result[ms.id] = get_weighted_total_for_marking_scheme_and_student(
        ms.id,
        assignment_marks,
        gef_marks)
    end
    result
  end

  def get_weighted_total_for_marking_scheme_and_student(
    ms_id,
    assignment_marks,
    gef_marks)

    weights_for_current_ms = MarkingWeight.where(marking_scheme_id: ms_id)

    weighted_assignment_total = 0
    assignment_marks.each do |a_id, mark|
      assignment_weight = weights_for_current_ms.where(is_assignment: true,
                                                       gradable_item_id: a_id)
      if assignment_weight != [] && mark
        weight = assignment_weight[0].weight
        # weight might be nil
        if weight
          weighted_mark = ((mark / get_max_mark_for_assignment(a_id)) * 100) *
                          (weight / 100)
          weighted_assignment_total += weighted_mark
        end
      end
    end

    weighted_gef_total = 0
    gef_marks.each do |gef_id, mark|
      gef_weight = weights_for_current_ms.where(is_assignment: false,
                                                gradable_item_id: gef_id)
      if gef_weight != 0 && mark
        weight = gef_weight[0].weight
        # weight might be nil
        if weight
          weighted_mark = ((mark / get_max_mark_for_grade_entry_from(gef_id)) *
            100) * (weight / 100)
          weighted_gef_total += weighted_mark
        end
      end
    end

    (weighted_assignment_total + weighted_gef_total).round(2)
  end
end
