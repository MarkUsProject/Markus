module CourseSummariesHelper

  # Get JSON data for the table
  def get_table_json_data(current_role)
    course = current_role.course
    course_information(course)

    if current_role.student?
      students = course.students.where(id: current_role.id)
      released = [true]
    else
      students = course.students
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
                                .order(:'results.created_at')
                                .pluck('role_id', 'groupings.assessment_id', 'results.total_mark')
    assignment_grades.each do |role_id, assessment_id, mark|
      max_mark = @max_marks[assessment_id]
      student_data[role_id][:assessment_marks][assessment_id] = {
        mark: mark,
        percentage: mark.nil? || max_mark.nil? ? nil : (mark * 100 / max_mark).round(2)
      }
    end
    gef_grades = students.joins(:grade_entry_students)
                         .where('grade_entry_students.released_to_student': released)
                         .pluck('role_id',
                                'grade_entry_students.assessment_id',
                                'grade_entry_students.total_grade')

    gef_grades.each do |role_id, assessment_id, mark|
      max_mark = @gef_max_marks[assessment_id]
      student_data[role_id][:assessment_marks][assessment_id] = {
        mark: mark,
        percentage: mark.nil? || max_mark.nil? ? nil : (mark * 100 / max_mark).round(2)
      }
    end

    unless current_role.student?
      calculate_course_grades(course, student_data)
    end
    student_data.values.sort_by { |x| x[:user_name] }
  end

  def course_information(course)
    @max_marks = Hash[
      course.assignments
            .joins(:criteria)
            .where('criteria.bonus': false)
            .group('assessments.id')
            .sum('criteria.max_mark')
    ]

    @gef_max_marks = course.grade_entry_forms
                           .unscoped
                           .joins(:grade_entry_items)
                           .where(grade_entry_items: { bonus: false })
                           .group('assessment_id')
                           .sum('grade_entry_items.out_of')
  end

  # Update student hashes with weighted grades for every marking scheme.
  def calculate_course_grades(course, students)
    course.marking_schemes.find_each do |scheme|
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
        student[:weighted_marks][scheme.id] = { mark: weighted.round(2).to_f, name: scheme.name }
      end
    end
  end
end
