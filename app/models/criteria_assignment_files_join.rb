class CriteriaAssignmentFilesJoin < ActiveRecord::Base
  belongs_to :criterion, polymorphic: true
  belongs_to :assignment_file
end
