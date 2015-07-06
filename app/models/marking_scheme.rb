class MarkingScheme < ActiveRecord::Base
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights
end
