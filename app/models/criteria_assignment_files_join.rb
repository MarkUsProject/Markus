class CriteriaAssignmentFilesJoin < ApplicationRecord
  belongs_to :criterion, polymorphic: true
  belongs_to :assignment_file
  accepts_nested_attributes_for :assignment_file, :criterion
end
