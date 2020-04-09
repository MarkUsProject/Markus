# Level represent a level within a Rubric Criterion
class Level < ApplicationRecord
  belongs_to :rubric_criterion

  validates :name, presence: true
  validates :description, presence: true
  validates :mark, presence: true

  validates_uniqueness_of :mark, scope: :rubric_criterion_id
  validates_numericality_of :mark, greater_than_or_equal_to: 0

  before_destroy :destroy_associated_marks
  before_update :update_associated_marks

  def destroy_associated_marks
    self.rubric_criterion.marks.where(mark: self.mark).update(mark: nil)
  end

  def update_associated_marks
    return unless self.changed.include?('mark')
    marks = self.rubric_criterion.marks
    before = self.changes['mark'][0]
    after = self.changes['mark'][1]
    marks.each do |mark|
      if mark.mark == before
        mark.update(mark: after)
      end
    end
  end
end
