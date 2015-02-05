module CourseSummariesHelper

	def get_data()
		all_students = Student.where(type: 'Student');
		all_assignments = Assignment.all();

		studentList = all_students.map do |student|
			{
				:id => student.id,
				:user_name => student.user_name,
				:first_name => student.first_name,
				:last_name => student.last_name,
				:marks => get_marks_for_student_for_assignment(student, all_assignments)
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

	def get_marks_for_student_for_assignment(student, all_assignments)
		marks = []
		all_assignments.each do |assignment|
			marks[assignment.id-1] = get_mark_for_assignment_and_student(assignment, student)
		end
		marks
	end

	def get_mark_for_assignment_and_student(assignment, student)
		grouping = get_grouping_for_user_for_assignment(student, assignment)
		if (grouping)
			submission = Submission.where(grouping_id: grouping.id).first
			if (submission)
				result = Result.where(submission_id: submission.id).first
				if (result)
					return result.total_mark
				end
			end
		end
		return nil
	end

	def get_grouping_for_user_for_assignment(student, assignment)
		memberships = Membership.where(user_id: student.id)
		if (memberships.count == 0)
			return nil
		end
		grouping = get_grouping_for_assignment(memberships, assignment)
		return grouping
	end

	def get_grouping_for_assignment(memberships, assignment)
		memberships.each do |membership|
			grouping = Grouping.where(id: membership.grouping_id).first
			if (grouping.assignment_id == assignment.id)
				return grouping
			end
		end
		return nil
	end

end
