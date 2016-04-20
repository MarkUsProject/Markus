module MarksGradersHelper
  # Return an array of TAs with the number of students they are assigned to on
  # this marks graders form
  def get_marks_graders_table_info(grade_entry_form)
    graders = Ta.all

    graders.map do |grader|
      s = grader.attributes
      s[:num_students] = grader.get_membership_count_by_grade_entry_form(
        grade_entry_form)
      s
    end
  end

  # Return an array of the students for this form and their assigned TAs
  def get_marks_graders_student_table_info(students, grade_entry_form)
    students.map do |student|
      s = student.attributes
      s[:graders] = lookup_graders_for_student(student, grade_entry_form)
      s[:section_name] = student.has_section? ? student.section.name : '-'
      s
    end
  end

  # Look up the currently associated TAs (graders)
  def lookup_graders_for_student(student, grade_entry_form)
    # Find the grade_entry_student which matches the form id
    grade_entry_student = student.grade_entry_students.find do |entry|
      entry.grade_entry_form_id == grade_entry_form.id
    end

    # Map their info
    graders = ''
    if !grade_entry_student.nil?
      graders = grade_entry_student.grade_entry_student_tas.map do |gest|
        m = {}
        m[:user_name] = gest.ta.user_name
        m[:membership_id] = gest.id
        m
      end
    end

    graders
  end

end
