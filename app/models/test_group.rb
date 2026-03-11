# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: test_groups
#
#  id                :integer          not null, primary key
#  autotest_settings :json             not null
#  display_output    :integer          default("instructors"), not null
#  name              :text             not null
#  position          :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  assessment_id     :bigint           not null
#  criterion_id      :bigint
#
# Indexes
#
#  index_test_groups_on_assessment_id  (assessment_id)
#  index_test_groups_on_criterion_id   (criterion_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class TestGroup < ApplicationRecord
  enum :display_output,
       { instructors: 0, instructors_and_student_tests: 1, instructors_and_students: 2 },
       prefix: :display_to

  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :test_groups
  belongs_to :criterion, optional: true
  has_many :test_group_results, dependent: :destroy
  has_one :course, through: :assignment

  validates :name, presence: true
  validates :display_output, presence: true
  validate :courses_should_match

  def to_json(*_args)
    result = self.autotest_settings
    result['extra_info'] = {
      'name' => name,
      'display_output' => display_output,
      'test_group_id' => id,
      'criterion' => criterion&.name
    }
    result
  end
end
