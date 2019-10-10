# Level represent a level within a Rubric Criterion
class Level < ApplicationRecord
  validates :name, presence: true
  validates :number, presence: true
  validates :description, presence: true
  validates :mark, presence: true

  validates_numericality_of :number, only_integer: true, greater_than_or_equal_to: 0, allow_nil: true
  validates_numericality_of :mark, greater_than_or_equal_to: 0
end
