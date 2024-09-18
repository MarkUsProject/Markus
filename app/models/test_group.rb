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
