module CourseSummariesHelper
  include SubmissionsHelper

  # Get JSON data for the table
  def get_table_json_data
    course_information
    all_students = Student.includes(accepted_groupings: { current_submission_used: [:submitted_remark, :non_pr_results] },
                                    grade_entry_students: :grades)
    student_list = all_students.all.map do |student|
      get_student_information(student)
    end
    student_list
  end

  def get_student_row_information
    course_information
    [get_student_information(@current_user, false)]
  end

  def course_information
    @all_assignments = Assignment.all
    @all_grade_entry_forms = GradeEntryForm.all
    if @current_user && @current_user.student?
      @all_schemes = MarkingScheme.none
      @weights = {}
      @gef_weights = {}
    else
      @all_schemes = MarkingScheme.all
      @weights = get_marking_weights_for_all_marking_schemes
      @gef_weights = get_gef_marking_weights_for_all_marking_schemes
    end

    rubric_max = RubricCriterion.group(:assessment_id).sum(:max_mark)
    flexible_max = FlexibleCriterion.group(:assessment_id).sum(:max_mark)
    checkbox_max = CheckboxCriterion.group(:assessment_id).sum(:max_mark)
    @max_marks = Hash[@all_assignments.map do |a|
      [a.id, rubric_max.fetch(a.id, 0) + flexible_max.fetch(a.id, 0) + checkbox_max.fetch(a.id, 0)]
    end
    ]

    @gef_max_marks = Hash[@all_grade_entry_forms.map do |gef|
      [gef.id, get_max_mark_for_grade_entry_form(gef.id)]
    end
    ]

    if @current_user && @current_user.student?
      @gef_marks = Grade.joins(grade_entry_student: :user, grade_entry_item: :grade_entry_form,)
                     .where(grade_entry_students: { released_to_student: true })
                     .group('grade_entry_students.user_id', 'grade_entry_items.grade_entry_form_id')
                     .sum('grade')
    else
      @gef_marks = Grade.joins(grade_entry_student: :user, grade_entry_item: :grade_entry_form)
                     .group('grade_entry_students.user_id', 'grade_entry_items.grade_entry_form_id')
                     .sum('grade')
    end
  end

  def get_student_information(student, marking_schemes = true)
    marks = get_mark_for_all_assignments_for_student(student, @all_assignments)
    gef_marks = get_mark_for_all_gef_for_student(
      student, @all_grade_entry_forms)

    data = {
        id: student.id,
        id_number: student.id_number,
        user_name: student.user_name,
        first_name: student.first_name,
        last_name: student.last_name,
        hidden: student.hidden,
        assignment_marks: marks,
        grade_entry_form_marks: gef_marks
    }

    if marking_schemes
      data[:weighted_marks] = get_weighted_total_for_all_marking_schemes_for_student(
        @all_schemes, marks, gef_marks, @weights,
        @gef_weights, @max_marks, @gef_max_marks)
    end

    data
  end

  # Get marks for all assignments for a student
  def get_mark_for_all_assignments_for_student(student, assignments)
    marks = Hash[assignments.map {|a| [a.id, 0]}]

    student.accepted_groupings.includes(:current_submission_used).each do |g|
      sub = g.current_submission_used
      # TODO: remove this defined? call. This is currently used because
      # this method is used in the MarkingScheme model, which does not define
      # current_user.
      if (!defined? current_user) || current_user.admin?
        marks[g.assignment_id] = sub ? sub.get_latest_result.total_mark : 0
      else
        if sub && sub.has_remark? && sub.remark_result.released_to_students
          marks[g.assignment_id] = sub.remark_result.total_mark
        elsif sub && sub.has_result? && sub.get_original_result.released_to_students
          marks[g.assignment_id] = sub.get_original_result.total_mark
        else
          marks[g.assignment_id] = 0
        end
      end
    end

    marks
  end

  def get_mark_for_all_gef_for_student(student, gefs)
    Hash[gefs.map {|gef| [gef.id, @gef_marks.fetch([student.id, gef.id], 0)]}]
  end

  def get_max_mark_for_grade_entry_form(gef_id)
    total = 0
    GradeEntryItem.where(grade_entry_form_id: gef_id, bonus: false).each do |gei|
      total += gei.out_of
    end
    total
  end

  # Return an object that contains a key for each marking
  # scheme. And the value is an object with keys as assignment ids
  # and the value the weight for that assignment
  def get_marking_weights_for_all_marking_schemes
    result = {}
    @all_schemes.each do |ms|
      result[ms.id] = {}
      MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: true).each do |mw|
        result[ms.id][mw.gradable_item_id] = mw.weight
      end
    end
    result
  end

  def get_gef_marking_weights_for_all_marking_schemes
    result = {}
    @all_schemes.each do |ms|
      result[ms.id] = {}
      MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: false).each do |mw|
        result[ms.id][mw.gradable_item_id] = mw.weight
      end
    end
    result
  end

  def get_weighted_total_for_all_marking_schemes_for_student(
    schemes,
    assignment_marks, gef_marks,
    weights, gef_weights,
    max_marks, gef_max_marks)

    result = {}
    schemes.each do |ms|
      result[ms.id] =
       get_weighted_total_for_marking_scheme_and_student(
         weights[ms.id], gef_weights[ms.id],
         assignment_marks, gef_marks,
         max_marks, gef_max_marks)
    end
    result
  end

  def get_weighted_total_for_marking_scheme_and_student(
    weights,
    gef_weights,
    assignment_marks,
    gef_marks,
    max_marks,
    gef_max_marks)

    weighted_assignment_total = 0
    assignment_marks.each do |a_id, mark|
      weight = weights[a_id]
      max_mark = max_marks[a_id]
      # max_mark might be 0
      if weight && max_mark > 0
        weighted_assignment_total += (mark / max_mark) * weight
      end
    end

    weighted_gef_total = 0
    gef_marks.each do |gef_id, mark|
      weight = gef_weights[gef_id]
      max_mark = gef_max_marks[gef_id]
      if weight && max_mark > 0
        weighted_gef_total += (mark / max_mark) * weight
      end
    end

    (weighted_assignment_total + weighted_gef_total).round(2).to_f
  end
end

