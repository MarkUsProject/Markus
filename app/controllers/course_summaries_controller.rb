class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  def index

    @assignments = Assignment.all();

    # get_data()

    # stu = Student.where(user_name: "g8butter").first;
    # puts stu.first_name
    # puts stu.type

    # puts Membership.where(user_id: stu.id)
    # mem_col = Membership.where(user_id: stu.id).first;

    # grping_id = mem_col.grouping_id;

    # sub = Submission.where(grouping_id: grping_id).first;

    # res = Result.where(submission_id: sub).first;

    # puts res.total_mark;
    # gpr = Grouping.where(id: grping_id).first
    # puts gpr.assignment_id
  	
  	# # get all students
  	# @students = Student.all(order: 'user_name')

  	# stu = @students[18] 

  	# # puts stu.memberships()

   #  puts "***GROUPS***"
   #  @groups = Group.all();
   #  @groups.each do |gr|
   #    puts gr.id
   #  end

   #  puts "***GROUPINGS***"
   #  # groupings
   #  @groupings = Grouping.all();
   #  @groupings.each do |group|
   #    puts group.group_id
   #    puts group.assignment_id
   #  end

   #  #results
   #  @results = Result.all();
   #  @results.each do |result|
   #    # puts result.submission_id
   #    # puts result.total_mark
   #  end
  	
  	# # all assignments
  	# @assignments = Assignment.all()
  	# @assignments.each do |assignment|
  	# 	# puts assignment.id
  	# end
  	
  	# # assign = @assignments[0].id

  	# # puts "here"
  	# # puts stu.has_pending_groupings_for?(1)
  	# # puts stu.has_pending_groupings_for?(2)
  	# # puts "end"

  end

  def populate
    render json: get_data()
  end
end
