class MarkingWeight < ApplicationRecord
  belongs_to :marking_scheme
  belongs_to :assessment
end
