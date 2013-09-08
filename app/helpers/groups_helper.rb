module GroupsHelper

  # Given a list of groupings and an assignment, constructs an array of table
  # rows to be insterted into the groupings FilterTable in the groups view.
  # Called whenever it is necessary to update the groupings table with multiple
  # changes.
  def construct_table_rows(groupings, assignment)
    result = {}
    groupings.each do |grouping|
      result[grouping.id] = construct_table_row(grouping, assignment)
    end
    result
  end

  # Given a list of students and an assignment, constructs an array of
  # table rows to be insterted into the students FilterTable in the groups view.
  # Called whenever it is necessary to update the students table with multiple
  # changes.
  def construct_student_table_rows(students, assignment)
    student_memberships = StudentMembership.all(:conditions => {:grouping_id => assignment.groupings, :user_id => students})
    students_in_assignment = student_memberships.collect do |membership|
      membership.user
    end
    result = {}
    students.each do |student|
      result[student.id] = construct_student_table_row(student, students_in_assignment)
    end
    result
  end

  # Given a grouping and an assignment, constructs a table row to be insterted
  # into the groupings FilterTable in the groups view.  Called whenever it
  # is necessary to update the groupings table.
  def construct_table_row(grouping, assignment)
      table_row = {}

      table_row[:id] = grouping.id
      table_row[:filter_table_row_contents] =
          render_to_string :partial => 'groups/table_row/filter_table_row.html.erb',
                           :locals => {
                               :grouping => grouping,
                               :assignment => assignment }

      table_row[:name] = grouping.group.group_name

      table_row[:members] = grouping.students.collect{ |student| student.user_name}.join(',')

#      used for searching
      table_row[:student_names] = grouping.students.collect{ |student| "#{student.first_name} #{student.last_name}"}.join(',')

      table_row[:valid] = grouping.is_valid?
      table_row[:filter_valid] = grouping.is_valid?

      table_row
  end

  # Given a student and all students belonging to an assignment
  # (assignment_memberships), constructs a table row to be insterted
  # into the students FilterTable in the groups view.  Called whenever it
  # is necessary to update the students table.
  def construct_student_table_row(student, students_in_assignment)
    table_row = {}

    table_row[:id] = student.id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'groups/table_row/filter_table_student_row', :locals => {:student => student}

    table_row[:user_name] = student.user_name
    table_row[:first_name] = student.first_name
    table_row[:last_name] = student.last_name
    table_row[:filter_student_assigned] = students_in_assignment.include?(student)

    table_row
end
end
