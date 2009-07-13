module StudentsHelper

  def construct_table_rows(students)
    result = {}
    students.each do |student|
      result[student.id] = construct_table_row(student)
    end
    return result
  end
  
  def construct_table_row(student) 
    result = {}
    result[:id] = student.id
    result[:user_name] = student.user_name
    result[:first_name] = student.first_name
    result[:last_name] = student.last_name
    result[:hidden] = student.hidden
    result[:edit] = render_to_string :partial => "students/table_row/edit", :locals => {:student => student}
    return result
  end

end
