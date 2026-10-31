# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: criteria_assignment_files_joins
#
#  id                 :integer          not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  assignment_file_id :integer          not null
#  criterion_id       :integer          not null
#
# Indexes
#
#  index_criteria_assignment_files_joins_on_assignment_file_id  (assignment_file_id)
#  index_criteria_assignment_files_joins_on_criterion_id        (criterion_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignment_file_id => assignment_files.id)
#  fk_rails_...  (criterion_id => criteria.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class CriteriaAssignmentFilesJoin < ApplicationRecord
  belongs_to :criterion
  belongs_to :assignment_file
  accepts_nested_attributes_for :assignment_file, :criterion
  has_one :course, through: :criterion
  validate :courses_should_match
end
