# Level represent a level within a Rubric Criterion
class Level < ApplicationRecord
  belongs_to :rubric_criterion

  validates :name, presence: true
  validates :description, presence: true
  validates :mark, presence: true

  validates_uniqueness_of :mark, scope: :rubric_criterion_id
  validates_numericality_of :mark, greater_than_or_equal_to: 0

  validate :only_update_if_results_unreleased

  def only_update_if_results_unreleased
    return if self.rubric_criterion.marks.empty?
    if (self.rubric_criterion.marks[0].result.released_to_students)
      errors.add(:level_id, 'Cannot update level once results are released.')
    end
  end
end
