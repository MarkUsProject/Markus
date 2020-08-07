# Level represents a level within a Rubric Criterion
class Level < ApplicationRecord
  belongs_to :criterion

  validates :name, presence: true
  validates_uniqueness_of :name, scope: :criterion_id

  validates :description, exclusion: { in: [nil] }

  validates :mark, presence: true
  validates_uniqueness_of :mark, scope: :criterion_id
  validates_numericality_of :mark, greater_than_or_equal_to: 0

  validate :only_update_if_results_unreleased

  before_destroy :destroy_associated_marks
  before_update :update_associated_marks

  def only_update_if_results_unreleased
    return if self.criterion.nil? # When the level is first being created
    unless self.criterion.results_unreleased?
      errors.add(:base, 'Cannot update level once results are released.')
    end
  end

  def destroy_associated_marks
    self.criterion.marks.where(mark: self.mark).update(mark: nil)
  end

  def update_associated_marks
    return unless self.changed.include?('mark')
    old_mark, new_mark = self.changes['mark']
    if self.criterion.changes.include?('max_mark')
      old_max_mark, new_max_mark = self.criterion.changes['max_mark']
      # Skip update if this change is caused
      return if old_mark * new_max_mark == new_mark * old_max_mark
    end
    self.criterion.marks.where(mark: old_mark).update(mark: new_mark)
  end
end
