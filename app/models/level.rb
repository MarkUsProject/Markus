class Level < ApplicationRecord
  belongs_to :rubric_criterion

  validates_numericality_of :number, only_integer: true, greater_than_or_equal_to: 0, allow_nil: true
  validates_numericality_of :mark, greater_than_or_equal_to: 0


end
