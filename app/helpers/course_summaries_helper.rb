module CourseSummariesHelper

	def get_data()
		all_students = Student.where(type: 'Student');
		all_assignments = Assignment.all();

		all_students.map do |student|
			s = {}
			s[:id] = student.id
			s[:user_name] = student.user_name
			s[:first_name] = student.first_name
			s[:last_name] = student.last_name
			s
		end

	end

	def get_marks_for_student_for_assignment(student_id, assignment_id)
	end

end
