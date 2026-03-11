# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: criteria_assignment_files_joins
#
#  id                 :integer          not null, primary key
#  created_at         :datetime
#  updated_at         :datetime
#  assignment_file_id :integer          not null
#  criterion_id       :integer          not null
#
# Foreign Keys
#
#  fk_rails_...  (assignment_file_id => assignment_files.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class CriteriaAssignmentFilesJoin < ApplicationRecord
  belongs_to :criterion
  belongs_to :assignment_file
  accepts_nested_attributes_for :assignment_file, :criterion
  has_one :course, through: :criterion
  validate :courses_should_match
end
