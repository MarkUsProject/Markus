class Submission < ActiveRecord::Base
  
  belongs_to  :assignment_file
  belongs_to  :group, :foreign_key => :group_number
  
  # TODO cannot submit if pending
end
