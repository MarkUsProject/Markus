# Let's create groups and groupings !

students = Student.all
a = Assignment.find_by_short_identifier("A1")

15.times do |time|
  student = students[time]
  group = Group.new
  group.group_name = student.user_name
  group.save
  grouping = Grouping.new
  grouping.group = group
  grouping.assignment = a
  grouping.save
  grouping.invite([student.user_name],
                  StudentMembership::STATUSES[:inviter],
                  invoked_by_admin=true)
end


