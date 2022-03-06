class TestGroup < ApplicationRecord
  enum display_output: { instructors: 0, instructors_and_student_tests: 1, instructors_and_students: 2 },
       _prefix: :display_to

  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :test_groups
  belongs_to :criterion, optional: true
  has_many :test_group_results, dependent: :delete_all
  has_one :course, through: :assignment

  validates :name, presence: true
  validates :display_output, presence: true
  validate :courses_should_match
end
