# A model that contains a mapping between a group, assignment, the 
# submission to be marked, the grade, and the TA that marked it.
class Grade < ActiveRecord::Base

  # Each grade is associated with one assignment
  # TODO: Necessary? Because we can get it through submission
  belongs_to :assignment

  # In particular, each grade is associated with the submission
  # for the assignment
  belongs_to :submission
  
  # Each grade is associated with some users, the student/group of students,
  # and the TA who gave the mark
  belongs_to :user # TA who graded it
  belongs_to :group # student (has membership to a group with one member) or student group
  
end
