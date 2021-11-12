class CriteriaAssignmentFilesJoin < ApplicationRecord
  belongs_to :criterion
  belongs_to :assignment_file
  accepts_nested_attributes_for :assignment_file, :criterion
  has_one :course, through: :criterion
end
