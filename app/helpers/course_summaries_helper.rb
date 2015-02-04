module CourseSummariesHelper

	def get_data()
		all_students = Student.where(type: 'Student');
		all_assignments = Assignment.all();

		studentList = all_students.map do |student|
			{
				:id => student.id,
				:user_name => student.user_name,
				:first_name => student.first_name,
				:last_name => student.last_name
			}
		end

		assignmentList = all_assignments.map do |assignment|
			{
				:id => assignment.id
			}
		end

		json = { :students => studentList, :assignments => assignmentList }.to_json
		studentList.to_json

	end

	def get_marks_for_student_for_assignment(student_id, assignment_id)
	end

end
