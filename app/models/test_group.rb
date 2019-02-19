class TestGroup < ApplicationRecord
  enum display_output: { instructors: 0, instructors_and_student_tests: 1, instructors_and_students: 2 },
       _prefix: :display_to

  belongs_to :assignment
  belongs_to :criterion, optional: true, polymorphic: true
  has_many :test_group_results, dependent: :delete_all

  validates :name, presence: true, uniqueness: { scope: :assignment_id }
  validates :run_by_instructors, :run_by_students, inclusion: { in: [true, false] }
  validates :display_output, presence: true

end
