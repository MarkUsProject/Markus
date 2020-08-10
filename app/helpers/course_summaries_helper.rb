module CourseSummariesHelper

  # Get JSON data for the table
  def get_table_json_data(current_user)
    course_information

    if current_user.student?
      students = Student.where(id: current_user.id)
      released = [true]
    else
      students = Student.all
      released = [true, false]
    end

    student_data = Hash[students.map do |student|
      [student.id,
       {
         id: student.id,
         id_number: student.id_number,
         user_name: student.user_name,
         first_name: student.first_name,
         last_name: student.last_name,
         hidden: student.hidden,
         assessment_marks: {}
       }]
    end]

    assignment_grades = students.joins(accepted_groupings: :current_result)
                                .where('results.released_to_students': released)
                                .pluck('users.id', 'groupings.assessment_id', 'results.total_mark')
    assignment_grades.each do |student_id, assessment_id, mark|
      student_data[student_id][:assessment_marks][assessment_id] = {
        mark: mark,
        percentage: mark.nil? ? nil : (mark * 100 / @max_marks[assessment_id]).round(2)
      }
    end

    gef_grades = students.joins(:grade_entry_students)
                         .where('grade_entry_students.released_to_student': released)
                         .pluck('users.id',
                                'grade_entry_students.assessment_id',
                                'grade_entry_students.total_grade')

    gef_grades.each do |student_id, assessment_id, mark|
      student_data[student_id][:assessment_marks][assessment_id] = {
        mark: mark,
        percentage: mark.nil? ? nil : (mark * 100 / @gef_max_marks[assessment_id]).round(2)
      }
    end

    unless current_user.student?
      calculate_course_grades(student_data)
    end
    student_data.values.sort_by { |x| x[:user_name] }
  end

  def course_information
    rubric_max = RubricCriterion.group(:assessment_id).sum(:max_mark)
    flexible_max = FlexibleCriterion.group(:assessment_id).sum(:max_mark)
    checkbox_max = CheckboxCriterion.group(:assessment_id).sum(:max_mark)
    @max_marks = Hash[Assignment.all.map do |a|
      [a.id, rubric_max.fetch(a.id, 0) + flexible_max.fetch(a.id, 0) + checkbox_max.fetch(a.id, 0)]
    end
    ]

    @gef_max_marks = GradeEntryForm.unscoped
                                   .joins(:grade_entry_items)
                                   .where(grade_entry_items: { bonus: false })
                                   .group('assessment_id')
                                   .sum('grade_entry_items.out_of')
  end

  # Update student hashes with weighted grades for every marking scheme.
  def calculate_course_grades(students)
    MarkingScheme.all.each do |scheme|
      students.each do |_, student|
        student[:weighted_marks] ||= {}
        weighted = 0
        scheme.marking_weights.each do |mw|
          if mw.assessment.type == 'Assignment'
            max_mark = @max_marks[mw.assessment_id]
          else
            max_mark = @gef_max_marks[mw.assessment_id]
          end
          mark = student[:assessment_marks][mw.assessment_id]&.[](:mark)
          unless mw.weight.nil? || mark.nil? || max_mark.nil? || max_mark == 0
            weighted += mark * mw.weight / max_mark
          end
        end
        student[:weighted_marks][scheme.id] = weighted.round(2).to_f
      end
    end
  end
end
