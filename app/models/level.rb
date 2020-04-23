# Level represents a level within a Rubric Criterion
class Level < ApplicationRecord
  belongs_to :rubric_criterion

  validates :name, presence: true
  validates :description, presence: true
  validates :mark, presence: true

  validates_uniqueness_of :mark, scope: :rubric_criterion_id
  validates_numericality_of :mark, greater_than_or_equal_to: 0

  validate :only_update_if_results_unreleased

  before_destroy :destroy_associated_marks
  before_update :update_associated_marks

  def only_update_if_results_unreleased
    self.rubric_criterion.results_unreleased?
    return if self.rubric_criterion.errors.empty?
    errors.add(:base, 'Cannot update level once results are released.')
  end

  def destroy_associated_marks
    self.rubric_criterion.marks.where(mark: self.mark).update(mark: nil)
  end

  def update_associated_marks
    return unless self.changed.include?('mark')
    mark_changes = self.changes['mark']
    self.rubric_criterion.marks.where(mark: mark_changes[0]).update(mark: mark_changes[1])
  end
end
