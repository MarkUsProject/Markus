class MarkingWeight < ApplicationRecord
  belongs_to :marking_scheme
  belongs_to :assessment
  has_one :course, through: :assessment
  validate :courses_should_match
end
