class TestGroup < ApplicationRecord
  enum display_output: { instructors: 0, instructors_and_student_tests: 1, instructors_and_students: 2 },
       _prefix: :display_to

  belongs_to :assignment, foreign_key: :assessment_id
  belongs_to :criterion, optional: true
  has_many :test_group_results, dependent: :delete_all

  validates :name, presence: true
  validates :display_output, presence: true

end
