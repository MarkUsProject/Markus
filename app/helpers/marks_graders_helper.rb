module MarksGradersHelper

  # Given a list of graders and a grade entry form, constructs an array of
  # table rows to be insterted into the graders FilterTable in the graders view.
  # Called whenever it is necessary to update the graders table with multiple
  # changes.
  def construct_grader_table_rows(graders, grade_entry_form)
    result = {}
    graders.each do |grader|
      result[grader.id] = construct_grader_table_row(grader, grade_entry_form)
    end
    return result
  end

  # Given a list of students and a grade entry form, constructs an array of
  # table rows to be insterted into the students FilterTable in the graders view.
  # Called whenever it is necessary to update the students table with multiple
  # changes.
  def construct_table_rows(students, grade_entry_form)
    result = {}
    students.each do |students|
      result[students.id] = construct_table_row(students, grade_entry_form)
    end
    return result
  end

  def construct_table_row(students, grade_entry_form)
      grade_entry_student = GradeEntryStudent.find_by_user_id(students.id)

      table_row = {}

      table_row[:id] = students.id
      table_row[:filter_table_row_contents] =
        render_to_string :partial => 'marks_graders/table_row/filter_table_row',
        :locals => {:student => students, :grade_entry_form => grade_entry_form}

      #These are used for sorting
      table_row[:user_name] = students.user_name
      table_row[:first_name] = students.first_name
      table_row[:last_name] = students.last_name
      table_row[:section] = students.section.nil? ? "" : students.section.name
      table_row[:members] = grade_entry_student.nil? ? "" : grade_entry_student.tas.collect{ |grader| grader.user_name}.join(',')

      #These are are used for searching
      table_row[:graders] = table_row[:members]

      return table_row
  end

  # Given a grader and a grade entry form, constructs a table row to be inserted
  # into the grader FilterTable in the graders view.  Called whenever it
  # is necessary to update the graders table.
  def construct_grader_table_row(grader, grade_entry_form)
    table_row = {}

    table_row[:id] = grader.id
    table_row[:filter_table_row_contents] =
      render_to_string :partial => 'marks_graders/table_row/filter_table_grader_row',
      :locals => {:grader => grader}

    #These used only for searching
    table_row[:first_name] = grader.first_name
    table_row[:last_name] = grader.last_name

    #These needed for sorting
    table_row[:user_name] = grader.user_name
    table_row[:full_name] = "#{grader.first_name} #{grader.last_name}"
    table_row[:num_students] = grader.get_membership_count_by_grade_entry_form(@grade_entry_form)

    return table_row
  end
  
end
